# No.5：Memorystore（セッション・キャッシュ。正本ではない）
resource "google_redis_instance" "cache" {
  project                 = var.project_id
  name                    = "${local.name}-cache"
  region                  = var.region
  tier                    = var.environment == "dev" ? "BASIC" : "STANDARD_HA"
  memory_size_gb          = var.redis_memory_gb
  redis_version           = "REDIS_7_2"
  authorized_network      = var.network
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  labels                  = local.labels
  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 18
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }
}

# No.5：Filestore（ティアは提案書 A-24）
resource "google_filestore_instance" "share" {
  project  = var.project_id
  name     = "${local.name}-fs"
  location = contains(["REGIONAL", "ENTERPRISE"], var.filestore_tier) ? var.region : var.zone
  tier     = var.filestore_tier
  labels   = local.labels
  file_shares {
    name        = "share"
    capacity_gb = var.filestore_capacity_gb
  }
  networks {
    network      = var.network
    modes        = ["MODE_IPV4"]
    connect_mode = "PRIVATE_SERVICE_ACCESS"
  }
  deletion_protection_enabled = var.deletion_protection
}
