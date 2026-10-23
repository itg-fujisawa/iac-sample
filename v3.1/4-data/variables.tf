variable "project_id" {
  type        = string
  description = "対象（ワークロード）Project ID。2-environments の出力"
}
variable "region" {
  type    = string
  default = "asia-northeast1"
}
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be dev, stg or prod."
  }
}
variable "cost_center" {
  type    = string
  default = "jpp-renewal"
}

variable "network" {
  type        = string
  description = "3-network output network"
}
variable "service_accounts" {
  type        = map(string)
  description = "2-environments output service_accounts"
}
variable "deletion_protection" {
  type    = bool
  default = true
}

# --- Cloud SQL（原本・マスタ） ---
variable "sql_tier" {
  type    = string
  default = "db-custom-2-7680"
}
variable "sql_ha" {
  type    = bool
  default = true
}
variable "sql_disk_size" {
  type    = number
  default = 100
}
variable "sql_retained_backups" {
  type    = number
  default = 14
}

# --- Spanner（検索・一覧用。提案書 項番8(4)） ---
variable "spanner_enabled" {
  type    = bool
  default = true
}
variable "spanner_processing_units" {
  type    = number
  default = 1000
}

# --- Memorystore / Filestore（No.5） ---
variable "redis_memory_gb" {
  type    = number
  default = 5
}
variable "filestore_tier" {
  type        = string
  default     = "REGIONAL"
  description = "提案書 A-24 に合わせる（例：REGIONAL / ZONAL / BASIC_SSD）"
}
variable "filestore_capacity_gb" {
  type    = number
  default = 1024
}
variable "zone" {
  type    = string
  default = "asia-northeast1-a"
}

# --- バックアップ／DR（No.1・2） ---
variable "dr_mode" {
  type    = string
  default = "cold"
  validation {
    condition     = contains(["none", "cold", "warm"], var.dr_mode)
    error_message = "dr_mode must be none, cold or warm."
  }
}
variable "dr_region" {
  type    = string
  default = "asia-northeast2"
}
variable "backup_bucket" {
  type        = string
  default     = ""
  description = "1-org output backup_buckets[env]（大阪・WORM）"
}
variable "spanner_export_enabled" {
  type    = bool
  default = true
}
