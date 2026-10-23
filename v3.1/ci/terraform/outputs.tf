output "attestor" {
  value = google_binary_authorization_attestor.build.id
}
output "kms_key_version" {
  value = data.google_kms_crypto_key_version.attest.id
}
output "artifact_repository" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}
output "build_source_bucket" {
  value = google_storage_bucket.build_src.name
}
