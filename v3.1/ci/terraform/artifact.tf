# アプリのコンテナ置き場（5-app-infra より先に作り、初回イメージをビルドできるようにする）
resource "google_artifact_registry_repository" "app" {
  project       = var.project_id
  location      = var.region
  repository_id = "${local.name}-app"
  format        = "DOCKER"
  labels        = local.labels
  docker_config {
    immutable_tags = true
  }
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 50
    }
  }
}

# Cloud Build のソース置き場（app-builder SA でビルドするため専用バケットを使う）
resource "google_storage_bucket" "build_src" {
  project                     = var.project_id
  name                        = "${var.project_id}-build-src"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "build_src_builder" {
  bucket = google_storage_bucket.build_src.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_accounts["app-builder"]}"
}

resource "google_storage_bucket_iam_member" "build_src_deployers" {
  for_each = var.deployers
  bucket   = google_storage_bucket.build_src.name
  role     = "roles/storage.objectCreator"
  member   = each.value
}

# アプリ CD に必要な追加権限
resource "google_project_iam_member" "builder_extra" {
  for_each = toset([
    "roles/containeranalysis.occurrences.editor", # 署名（attestation）の作成・脆弱性結果の参照
    "roles/binaryauthorization.attestorsVerifier",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.service_accounts["app-builder"]}"
}

# Cloud Run Jobs のイメージ更新（batch-job SA で実行されるため actAs が必要）
resource "google_service_account_iam_member" "builder_actas_batch" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_accounts["batch-job"]}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.service_accounts["app-builder"]}"
}

resource "google_project_iam_member" "deployers" {
  for_each = var.deployers
  project  = var.project_id
  role     = "roles/cloudbuild.builds.editor"
  member   = each.value
}
resource "google_service_account_iam_member" "deployers_actas_builder" {
  for_each           = var.deployers
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_accounts["app-builder"]}"
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

# stg → prod 昇格用の読取り（app-promote.yaml）
resource "google_artifact_registry_repository_iam_member" "promote_reader" {
  for_each   = var.promote_readers
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}
