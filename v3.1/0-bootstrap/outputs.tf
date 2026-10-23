output "common_folder_id" {
  value = google_folder.common.name
}
output "iac_project_id" {
  value = google_project.iac.project_id
}
output "executor_sa" {
  value = { for k, v in google_service_account.executor : k => v.email }
}
output "ci_sa" {
  value = google_service_account.ci.email
}
output "bootstrap_state_bucket" {
  value = google_storage_bucket.state.name
}
output "evidence_bucket" {
  value = google_storage_bucket.evidence.name
}
