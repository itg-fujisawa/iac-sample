# No.1・2：大阪の WORM バケット（prj-common-backup）へ日次複製
data "google_storage_transfer_project_service_account" "sts" {
  project = var.project_id
}

resource "google_storage_bucket_iam_member" "sts_source" {
  count  = var.backup_bucket != "" ? 1 : 0
  bucket = google_storage_bucket.documents.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}
resource "google_storage_bucket_iam_member" "sts_source_legacy" {
  count  = var.backup_bucket != "" ? 1 : 0
  bucket = google_storage_bucket.documents.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}

resource "google_storage_transfer_job" "documents_to_osaka" {
  count       = var.backup_bucket != "" ? 1 : 0
  project     = var.project_id
  description = "${local.name} documents daily copy to Osaka WORM bucket"
  transfer_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.documents.name
    }
    gcs_data_sink {
      bucket_name = var.backup_bucket
      path        = "documents/"
    }
    transfer_options {
      overwrite_objects_already_existing_in_sink = false
      delete_objects_from_source_after_transfer  = false
    }
  }
  schedule {
    schedule_start_date {
      year  = 2026
      month = 11
      day   = 1
    }
    start_time_of_day {
      hours   = 19
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
  depends_on = [google_storage_bucket_iam_member.sts_source, google_storage_bucket_iam_member.sts_source_legacy]
}

# Spanner 日次エクスポート（Dataflow テンプレート）→ 大阪 WORM バケット
resource "google_cloud_scheduler_job" "spanner_export" {
  count     = var.spanner_enabled && var.spanner_export_enabled && var.backup_bucket != "" ? 1 : 0
  project   = var.project_id
  region    = var.region
  name      = "${local.name}-spanner-export"
  schedule  = "0 2 * * *"
  time_zone = "Asia/Tokyo"
  http_target {
    http_method = "POST"
    uri         = "https://dataflow.googleapis.com/v1b3/projects/${var.project_id}/locations/${var.region}/templates:launch?gcsPath=gs://dataflow-templates-${var.region}/latest/Cloud_Spanner_to_GCS_Avro"
    body = base64encode(jsonencode({
      jobName = "${local.name}-spanner-export"
      parameters = {
        instanceId = google_spanner_instance.search[0].name
        databaseId = google_spanner_database.search[0].name
        outputDir  = "gs://${var.backup_bucket}/spanner/"
      }
      environment = {
        serviceAccountEmail = var.service_accounts["backup-ops"]
        subnetwork          = "regions/${var.region}/subnetworks/${local.name}-batch"
        ipConfiguration     = "WORKER_IP_PRIVATE"
      }
    }))
    oauth_token {
      service_account_email = var.service_accounts["backup-ops"]
    }
  }
}

check "backup_bucket_required" {
  assert {
    condition     = var.environment == "dev" || var.backup_bucket != ""
    error_message = "stg/prod は大阪 WORM バケット（1-org output backup_buckets）を指定すること（提案書 項番11・15）。"
  }
}
