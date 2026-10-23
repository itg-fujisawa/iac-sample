# No.8：ログ12か月以上保管・ロック・BigQuery 横断検索（監査専用 Project）
resource "google_logging_project_bucket_config" "audit" {
  project          = google_project.common["audit"].project_id
  location         = var.region
  bucket_id        = "jpp-audit"
  retention_days   = var.audit_retention_days
  locked           = var.lock_audit_bucket
  enable_analytics = true
  depends_on       = [google_project_service.common]
}

resource "google_logging_linked_dataset" "audit" {
  link_id     = "jpp_audit"
  bucket      = google_logging_project_bucket_config.audit.id
  description = "BigQuery linked dataset for cross-environment search"
}

# 組織シンク：監査ログ＋LB＋Cloud Run＋Armor を全 Project から集約
resource "google_logging_organization_sink" "audit" {
  name             = "jpp-audit-sink"
  org_id           = var.org_id
  include_children = true
  destination      = "logging.googleapis.com/${google_logging_project_bucket_config.audit.id}"
  filter           = <<-EOT
    logName:"cloudaudit.googleapis.com"
    OR resource.type="http_load_balancer"
    OR resource.type="cloud_run_revision"
    OR resource.type="cloud_run_job"
    OR jsonPayload.enforcedSecurityPolicy.name:*
  EOT
}

resource "google_project_iam_member" "audit_sink_writer" {
  project = google_project.common["audit"].project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.audit.writer_identity
}

resource "google_project_iam_member" "audit_viewer" {
  for_each = var.audit_viewers
  project  = google_project.common["audit"].project_id
  role     = "roles/logging.viewAccessor"
  member   = each.value
}
