# No.3：Cloud Armor（WAF・レート制限・Adaptive Protection・reCAPTCHA）
locals {
  waf_rules = {
    "3000" = "sqli-v33-stable"
    "3001" = "xss-v33-stable"
    "3002" = "lfi-v33-stable"
    "3003" = "rfi-v33-stable"
    "3004" = "rce-v33-stable"
    "3005" = "methodenforcement-v33-stable"
    "3006" = "scannerdetection-v33-stable"
    "3007" = "protocolattack-v33-stable"
    "3008" = "sessionfixation-v33-stable"
  }
}

resource "google_recaptcha_enterprise_key" "armor" {
  count        = var.recaptcha_enabled ? 1 : 0
  project      = var.project_id
  display_name = "${local.name}-armor-redirect"
  labels       = local.labels
  web_settings {
    integration_type  = "INVISIBLE"
    allowed_domains   = var.domains
    allow_amp_traffic = false
  }
}

resource "google_compute_security_policy" "backend" {
  project     = var.project_id
  name        = "${local.name}-armor"
  description = "JPP backend policy: allowlist, OWASP CRS, rate limits, Adaptive Protection"
  type        = "CLOUD_ARMOR"

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = "STANDARD"
    }
  }

  dynamic "recaptcha_options_config" {
    for_each = var.recaptcha_enabled ? [1] : []
    content {
      redirect_site_key = google_recaptcha_enterprise_key.armor[0].name
    }
  }

  # 許可 IP（非公開サイト・管理画面）
  dynamic "rule" {
    for_each = { for i, c in chunklist(var.allowed_cidrs, 10) : tostring(i) => c }
    content {
      priority    = 1000 + tonumber(rule.key)
      action      = "allow"
      description = "Allowed source IPs"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
    }
  }

  # OWASP 事前構成ルール
  dynamic "rule" {
    for_each = local.waf_rules
    content {
      priority    = tonumber(rule.key)
      action      = "deny(403)"
      preview     = var.waf_preview
      description = "OWASP ${rule.value}"
      match {
        expr {
          expression = "evaluatePreconfiguredWaf('${rule.value}', {'sensitivity': ${var.waf_sensitivity}})"
        }
      }
    }
  }

  # パス単位の流量制御
  dynamic "rule" {
    for_each = var.path_throttles
    content {
      priority    = rule.value.priority
      action      = "throttle"
      description = "Throttle ${rule.value.path}"
      match {
        expr {
          expression = "request.path.startsWith('${rule.value.path}')"
        }
      }
      rate_limit_options {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"
        rate_limit_threshold {
          count        = rule.value.count
          interval_sec = 60
        }
      }
    }
  }

  # 全体レート制限（IP 単位でバン）
  rule {
    priority    = 5000
    action      = "rate_based_ban"
    description = "Global per-IP rate limit"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600
      rate_limit_threshold {
        count        = var.rl_global_count
        interval_sec = 60
      }
    }
  }

  rule {
    priority    = 2147483647
    action      = var.public_site ? "allow" : "deny(403)"
    description = "Default"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.public_site || length(var.allowed_cidrs) > 0
      error_message = "非公開サイトは allowed_cidrs を1つ以上指定すること。"
    }
  }
}

# CDN 前段（Edge）：IP 制御のみ。WAF・レート制限は backend 側で実施
resource "google_compute_security_policy" "edge" {
  project     = var.project_id
  name        = "${local.name}-armor-edge"
  description = "Edge policy for CDN-enabled backends (IP allow/deny only)"
  type        = "CLOUD_ARMOR_EDGE"

  dynamic "rule" {
    for_each = { for i, c in chunklist(var.allowed_cidrs, 10) : tostring(i) => c }
    content {
      priority    = 1000 + tonumber(rule.key)
      action      = "allow"
      description = "Allowed source IPs"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
    }
  }
  rule {
    priority    = 2147483647
    action      = var.public_site ? "allow" : "deny(403)"
    description = "Default"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

check "waf_enforced_in_prod" {
  assert {
    condition     = var.environment != "prod" || !var.waf_preview
    error_message = "prod は WAF を強制モード（waf_preview=false）にすること。"
  }
}
