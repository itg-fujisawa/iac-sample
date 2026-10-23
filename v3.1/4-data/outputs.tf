output "sql_connection_name" {
  value = google_sql_database_instance.main.connection_name
}
output "sql_private_ip" {
  value = google_sql_database_instance.main.private_ip_address
}
output "spanner_database" {
  value = var.spanner_enabled ? google_spanner_database.search[0].id : ""
}
output "redis_host" {
  value = google_redis_instance.cache.host
}
output "filestore_ip" {
  value = google_filestore_instance.share.networks[0].ip_addresses[0]
}
output "documents_bucket" {
  value = google_storage_bucket.documents.name
}
output "app_secret_id" {
  value = google_secret_manager_secret.app.secret_id
}
