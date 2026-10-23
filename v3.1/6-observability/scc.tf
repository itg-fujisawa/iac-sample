# No.7：SCC（Premium は組織側で有効化）の検出結果を Pub/Sub へ通知
resource "google_pubsub_topic" "scc" {
  count   = var.scc_notification_enabled ? 1 : 0
  project = var.project_id
  name    = "${local.name}-scc-findings"
  labels  = local.labels
}

resource "google_scc_v2_project_notification_config" "findings" {
  count        = var.scc_notification_enabled ? 1 : 0
  project      = var.project_id
  location     = "global"
  config_id    = "${local.name}-findings"
  description  = "High/Critical findings"
  pubsub_topic = google_pubsub_topic.scc[0].id
  streaming_config {
    filter = var.scc_filter
  }
}

resource "google_pubsub_subscription" "scc" {
  count                      = var.scc_notification_enabled ? 1 : 0
  project                    = var.project_id
  name                       = "${local.name}-scc-findings-sub"
  topic                      = google_pubsub_topic.scc[0].id
  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"
}

# 未処理滞留の監視（通知の取りこぼし検知）
resource "google_monitoring_alert_policy" "scc_backlog" {
  count                 = var.scc_notification_enabled ? 1 : 0
  project               = var.project_id
  display_name          = "${local.name} SCC findings backlog"
  combiner              = "OR"
  notification_channels = local.channels
  conditions {
    display_name = "oldest unacked > 1h"
    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND resource.label.subscription_id = \"${google_pubsub_subscription.scc[0].name}\" AND metric.type = \"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3600
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }
}
