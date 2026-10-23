output "env_folder_ids" {
  value = { for k, v in google_folder.env : k => v.name }
}
output "audit_project_id" {
  value = google_project.common["audit"].project_id
}
output "backup_project_id" {
  value = google_project.common["backup"].project_id
}
output "backup_buckets" {
  value = { for k, v in google_storage_bucket.backup : k => v.name }
}
output "sorry_bucket" {
  value = google_storage_bucket.sorry.name
}
output "audit_log_bucket" {
  value = google_logging_project_bucket_config.audit.id
}
