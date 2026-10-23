output "notification_channels" {
  value = local.channels
}
output "scc_topic" {
  value = var.scc_notification_enabled ? google_pubsub_topic.scc[0].id : ""
}
