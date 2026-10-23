# Spanner（検索・一覧用）。DR でも regional 東京＋Enterprise を維持（No.1・12）
resource "google_spanner_instance" "search" {
  count                        = var.spanner_enabled ? 1 : 0
  project                      = var.project_id
  name                         = "${local.name}-search"
  display_name                 = "${local.name}-search"
  config                       = "regional-${var.region}"
  edition                      = "ENTERPRISE"
  processing_units             = var.spanner_processing_units
  force_destroy                = false
  default_backup_schedule_type = "NONE"
  labels                       = local.labels
}

resource "google_spanner_database" "search" {
  count                    = var.spanner_enabled ? 1 : 0
  project                  = var.project_id
  instance                 = google_spanner_instance.search[0].name
  name                     = "patent-search"
  database_dialect         = "GOOGLE_STANDARD_SQL"
  version_retention_period = "7d"
  deletion_protection      = var.deletion_protection
  enable_drop_protection   = var.deletion_protection
  ddl                      = [for s in split(";", file("${path.module}/sql/search-schema.sql")) : trimspace(s) if trimspace(s) != ""]
}

# 参照のみ：app-runtime
resource "google_spanner_database_iam_member" "reader" {
  count    = var.spanner_enabled ? 1 : 0
  project  = var.project_id
  instance = google_spanner_instance.search[0].name
  database = google_spanner_database.search[0].name
  role     = "roles/spanner.databaseReader"
  member   = "serviceAccount:${var.service_accounts["app-runtime"]}"
}

# 同期処理：fine-grained access（DDL 権限を与えない）
resource "google_spanner_database_iam_member" "indexer_fgac" {
  for_each = var.spanner_enabled ? toset(["roles/spanner.fineGrainedAccessUser"]) : toset([])
  project  = var.project_id
  instance = google_spanner_instance.search[0].name
  database = google_spanner_database.search[0].name
  role     = each.value
  member   = "serviceAccount:${var.service_accounts["indexer"]}"
}
resource "google_spanner_database_iam_member" "indexer_role" {
  count    = var.spanner_enabled ? 1 : 0
  project  = var.project_id
  instance = google_spanner_instance.search[0].name
  database = google_spanner_database.search[0].name
  role     = "roles/spanner.databaseRoleUser"
  member   = "serviceAccount:${var.service_accounts["indexer"]}"
  condition {
    title      = "indexer-role-only"
    expression = "resource.type == \"spanner.googleapis.com/DatabaseRole\" && resource.name.endsWith(\"/indexer\")"
  }
}

resource "google_spanner_backup_schedule" "daily" {
  count              = var.spanner_enabled ? 1 : 0
  project            = var.project_id
  instance           = google_spanner_instance.search[0].name
  database           = google_spanner_database.search[0].name
  name               = "daily-full"
  retention_duration = "604800s"
  spec {
    cron_spec {
      text = "0 18 * * *"
    }
  }
  full_backup_spec {}
}

check "spanner_required" {
  assert {
    condition     = var.environment == "dev" || var.spanner_enabled
    error_message = "提案書 項番8(4)：stg/prod は Spanner（検索・一覧用）を有効にすること。"
  }
}
