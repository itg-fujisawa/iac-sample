output "lb_ip" {
  value = google_compute_global_address.web.address
}
output "services" {
  value = { for k, v in google_cloud_run_v2_service.svc : k => v.name }
}
output "security_policy" {
  value = google_compute_security_policy.backend.name
}
output "jobs" {
  value = { for k, v in google_cloud_run_v2_job.job : k => v.name }
}
