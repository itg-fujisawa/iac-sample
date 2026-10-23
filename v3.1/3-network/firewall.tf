# No.6：ネットワークファイアウォールポリシー（既定拒否＋許可リスト）
resource "google_compute_network_firewall_policy" "main" {
  project     = var.project_id
  name        = "${local.name}-fw"
  description = "JPP baseline: deny-by-default egress, explicit allow from 外部接続調整表"
}

resource "google_compute_network_firewall_policy_association" "main" {
  project           = var.project_id
  name              = "${local.name}-fw-assoc"
  firewall_policy   = google_compute_network_firewall_policy.main.name
  attachment_target = google_compute_network.main.id
}

# Google ヘルスチェック・IAP（運用VM）
resource "google_compute_network_firewall_policy_rule" "allow_hc_iap" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.main.name
  rule_name       = "allow-hc-iap"
  priority        = 1000
  direction       = "INGRESS"
  action          = "allow"
  enable_logging  = true
  match {
    src_ip_ranges = ["35.191.0.0/16", "130.211.0.0/22", "35.235.240.0/20"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["22", "80", "443", "8080"]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_internal" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.main.name
  rule_name       = "allow-internal"
  priority        = 1100
  direction       = "INGRESS"
  action          = "allow"
  match {
    src_ip_ranges = concat([for s in var.subnets : s.cidr], ["${var.psa_address}/${var.psa_prefix_length}"])
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_google_apis" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.main.name
  rule_name       = "allow-private-google-access"
  priority        = 1200
  direction       = "EGRESS"
  action          = "allow"
  match {
    dest_ip_ranges = ["199.36.153.8/30", "199.36.153.4/30"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_internal_egress" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.main.name
  rule_name       = "allow-internal-egress"
  priority        = 1300
  direction       = "EGRESS"
  action          = "allow"
  match {
    dest_ip_ranges = concat([for s in var.subnets : s.cidr], ["${var.psa_address}/${var.psa_prefix_length}"])
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "egress_allow" {
  for_each        = var.egress_allow_rules
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.main.name
  rule_name       = each.key
  description     = each.value.description
  priority        = each.value.priority
  direction       = "EGRESS"
  action          = "allow"
  enable_logging  = true
  match {
    dest_ip_ranges = each.value.dest_ranges
    layer4_configs {
      ip_protocol = each.value.protocol
      ports       = each.value.ports
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "deny_all_egress" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.main.name
  rule_name       = "deny-all-egress"
  priority        = 65000
  direction       = "EGRESS"
  action          = "deny"
  enable_logging  = true
  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}
