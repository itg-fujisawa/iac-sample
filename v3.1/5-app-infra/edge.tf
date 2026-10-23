# 外部 Application LB（EXTERNAL_MANAGED）＋ CDN ＋ Cloud Armor
resource "google_compute_global_address" "web" {
  project = var.project_id
  name    = "${local.name}-web-ip"
}

resource "google_compute_region_network_endpoint_group" "svc" {
  for_each              = var.services
  project               = var.project_id
  name                  = "${local.name}-${each.key}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.svc[each.key].name
  }
}

resource "google_compute_backend_service" "svc" {
  for_each              = var.services
  project               = var.project_id
  name                  = "${local.name}-${each.key}-be"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  security_policy       = google_compute_security_policy.backend.id
  edge_security_policy  = each.value.cdn ? google_compute_security_policy.edge.id : null
  enable_cdn            = each.value.cdn
  # No.3：X-Robots-Tag（提案書 項番21）
  custom_response_headers = contains(var.robots_noindex_paths, each.key) ? ["X-Robots-Tag: noindex, nofollow"] : []

  dynamic "cdn_policy" {
    for_each = each.value.cdn ? [1] : []
    content {
      cache_mode                   = "USE_ORIGIN_HEADERS"
      signed_url_cache_max_age_sec = 0
      negative_caching             = false
    }
  }
  backend {
    group = google_compute_region_network_endpoint_group.svc[each.key].id
  }
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# No.11：Sorry（大阪バケット、prj-common-sorry 所有）
resource "google_compute_backend_bucket" "sorry" {
  project     = var.project_id
  name        = "${local.name}-sorry"
  bucket_name = var.sorry_bucket
  enable_cdn  = false
}

resource "google_compute_url_map" "web" {
  project         = var.project_id
  name            = "${local.name}-urlmap"
  default_service = var.maintenance_mode ? google_compute_backend_bucket.sorry.id : google_compute_backend_service.svc[var.default_service].id

  dynamic "host_rule" {
    for_each = var.maintenance_mode ? [] : [1]
    content {
      hosts        = ["*"]
      path_matcher = "main"
    }
  }
  dynamic "path_matcher" {
    for_each = var.maintenance_mode ? [] : [1]
    content {
      name            = "main"
      default_service = google_compute_backend_service.svc[var.default_service].id
      dynamic "path_rule" {
        for_each = { for k, v in var.services : k => v if length(v.paths) > 0 }
        content {
          paths   = path_rule.value.paths
          service = google_compute_backend_service.svc[path_rule.key].id
        }
      }
    }
  }
  lifecycle {
    precondition {
      condition     = contains(keys(var.services), var.default_service)
      error_message = "default_service must be a key of services."
    }
  }
}

resource "google_compute_managed_ssl_certificate" "web" {
  project = var.project_id
  name    = "${local.name}-cert"
  managed {
    domains = var.domains
  }
}

resource "google_compute_ssl_policy" "modern" {
  project         = var.project_id
  name            = "${local.name}-tls12"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_target_https_proxy" "web" {
  project          = var.project_id
  name             = "${local.name}-https"
  url_map          = google_compute_url_map.web.id
  ssl_certificates = [google_compute_managed_ssl_certificate.web.id]
  ssl_policy       = google_compute_ssl_policy.modern.id
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${local.name}-https"
  ip_address            = google_compute_global_address.web.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.web.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# HTTP → HTTPS リダイレクト
resource "google_compute_url_map" "redirect" {
  project = var.project_id
  name    = "${local.name}-redirect"
  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}
resource "google_compute_target_http_proxy" "redirect" {
  project = var.project_id
  name    = "${local.name}-http"
  url_map = google_compute_url_map.redirect.id
}
resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "${local.name}-http"
  ip_address            = google_compute_global_address.web.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
