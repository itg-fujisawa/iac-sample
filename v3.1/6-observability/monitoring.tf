resource "google_monitoring_notification_channel" "email" {
  for_each     = toset(var.alert_emails)
  project      = var.project_id
  display_name = "ops-${each.value}"
  type         = "email"
  labels = {
    email_address = each.value
  }
}

locals {
  channels = [for c in google_monitoring_notification_channel.email : c.id]
}

resource "google_monitoring_alert_policy" "run_5xx" {
  for_each              = var.services
  project               = var.project_id
  display_name          = "${local.name} ${each.key} 5xx"
  combiner              = "OR"
  notification_channels = local.channels
  conditions {
    display_name = "5xx > 5 in 5 min"
    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.label.service_name = \"${each.value}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.label.response_code_class = \"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
  documentation {
    mime_type = "text/markdown"
    content   = "Cloud Run のリビジョンログ、直近の配備、DB 接続を確認。runbooks/incident.md 参照。"
  }
}

resource "google_monitoring_alert_policy" "run_latency" {
  for_each              = var.services
  project               = var.project_id
  display_name          = "${local.name} ${each.key} p95 latency"
  combiner              = "OR"
  notification_channels = local.channels
  conditions {
    display_name = "p95 > ${var.latency_threshold_ms} ms for 5 min"
    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.label.service_name = \"${each.value}\" AND metric.type = \"run.googleapis.com/request_latencies\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
    }
  }
}

resource "google_monitoring_uptime_check_config" "web" {
  count        = var.uptime_host != "" ? 1 : 0
  project      = var.project_id
  display_name = "${local.name} HTTPS health"
  timeout      = "10s"
  period       = "60s"
  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.uptime_host
    }
  }
}

resource "google_monitoring_alert_policy" "uptime" {
  count                 = var.uptime_host != "" ? 1 : 0
  project               = var.project_id
  display_name          = "${local.name} HTTPS unavailable"
  combiner              = "OR"
  notification_channels = local.channels
  conditions {
    display_name = "uptime check failed"
    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id = \"${google_monitoring_uptime_check_config.web[0].uptime_check_id}\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "120s"
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }
      trigger {
        count = 2
      }
    }
  }
}

# Cloud Armor の拒否急増（攻撃兆候）
resource "google_logging_metric" "armor_denied" {
  project = var.project_id
  name    = "${local.name}-armor-denied"
  filter  = "resource.type=\"http_load_balancer\" AND jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
resource "google_monitoring_alert_policy" "armor_denied" {
  project               = var.project_id
  display_name          = "${local.name} Cloud Armor deny spike"
  combiner              = "OR"
  notification_channels = local.channels
  conditions {
    display_name = "deny > 1000 in 5 min"
    condition_threshold {
      filter          = "resource.type = \"l7_lb_rule\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.armor_denied.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1000
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
}
