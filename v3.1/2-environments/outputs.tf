output "project_id" {
  value = google_project.workload.project_id
}
output "project_number" {
  value = google_project.workload.number
}
output "service_accounts" {
  value = { for k, v in google_service_account.sa : k => v.email }
}
# 1-org の backup_writers[env] へ設定（2巡目）
output "backup_writer_members" {
  value = [
    "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}",
    "serviceAccount:${google_service_account.sa["backup-ops"].email}",
  ]
}
