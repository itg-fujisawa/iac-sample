# Cloud SQL for PostgreSQL（原本・マスタ）。stg/prod は HA 必須（No.9）
resource "google_sql_database_instance" "main" {
  project             = var.project_id
  name                = "${local.name}-pg"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = var.deletion_protection
  settings {
    tier                        = var.sql_tier
    edition                     = "ENTERPRISE"
    availability_type           = var.sql_ha ? "REGIONAL" : "ZONAL"
    disk_type                   = "PD_SSD"
    disk_size                   = var.sql_disk_size
    disk_autoresize             = true
    deletion_protection_enabled = var.deletion_protection
    user_labels                 = local.labels
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network
      ssl_mode        = "ENCRYPTED_ONLY"
    }
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "18:00"
      transaction_log_retention_days = 7
      location                       = var.dr_mode == "none" ? var.region : var.dr_region # No.2：大阪に保管
      backup_retention_settings {
        retained_backups = var.sql_retained_backups
        retention_unit   = "COUNT"
      }
    }
    maintenance_window {
      day          = 7
      hour         = 18
      update_track = "stable"
    }
    insights_config {
      query_insights_enabled = true
    }
  }
  lifecycle {
    precondition {
      condition     = var.environment == "dev" || var.sql_ha
      error_message = "stg/prod は Cloud SQL を REGIONAL（HA）にすること（提案書 項番10(5)・11）。"
    }
  }
}

resource "google_sql_database" "app" {
  project  = var.project_id
  name     = "patent"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "iam_sa" {
  for_each = toset(["app-runtime", "batch-job", "mig-batch"])
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  name     = trimsuffix(var.service_accounts[each.value], ".gserviceaccount.com")
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

# warm（提案外オプション）時のみ大阪クロスリージョンレプリカ
resource "google_sql_database_instance" "replica_dr" {
  count                = var.dr_mode == "warm" ? 1 : 0
  project              = var.project_id
  name                 = "${local.name}-pg-dr"
  region               = var.dr_region
  database_version     = "POSTGRES_16"
  master_instance_name = google_sql_database_instance.main.name
  deletion_protection  = var.deletion_protection
  settings {
    tier              = var.sql_tier
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network
      ssl_mode        = "ENCRYPTED_ONLY"
    }
  }
}
