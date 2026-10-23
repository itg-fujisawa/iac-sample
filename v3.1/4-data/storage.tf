# 原本（公報 PDF/XML 等）
resource "google_storage_bucket" "documents" {
  project                     = var.project_id
  name                        = "${var.project_id}-documents"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels
  versioning {
    enabled = true
  }
  soft_delete_policy {
    retention_duration_seconds = 604800
  }
}

resource "google_storage_bucket_iam_member" "documents_reader" {
  for_each = toset(["app-runtime", "indexer", "batch-job"])
  bucket   = google_storage_bucket.documents.name
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${var.service_accounts[each.value]}"
}
resource "google_storage_bucket_iam_member" "documents_writer" {
  for_each = toset(["batch-job", "mig-batch"])
  bucket   = google_storage_bucket.documents.name
  role     = "roles/storage.objectUser"
  member   = "serviceAccount:${var.service_accounts[each.value]}"
}

# アプリ設定の Secret（値は Terraform に渡さない）
resource "google_secret_manager_secret" "app" {
  project   = var.project_id
  secret_id = "${local.name}-app-config"
  labels    = local.labels
  replication {
    user_managed {
      replicas {
        location = var.region
      }
      replicas {
        location = var.dr_region
      }
    }
  }
}
resource "google_secret_manager_secret_iam_member" "app" {
  for_each  = toset(["app-runtime", "batch-job"])
  project   = var.project_id
  secret_id = google_secret_manager_secret.app.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_accounts[each.value]}"
}
