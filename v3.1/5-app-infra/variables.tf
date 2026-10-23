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
  type = string
}
variable "subnets" {
  type        = map(string)
  description = "3-network output subnets"
}
variable "service_accounts" {
  type = map(string)
}
variable "sql_connection_name" {
  type = string
}
variable "spanner_database" {
  type    = string
  default = ""
}
variable "redis_host" {
  type    = string
  default = ""
}
variable "db_name" {
  type    = string
  default = "patent"
}
variable "db_pool_max" {
  type        = number
  default     = 5
  description = "1インスタンスあたりの接続数。max_instances 合計 × db_pool_max ≦ Cloud SQL 最大接続数"
}
variable "app_secret_id" {
  type        = string
  default     = ""
  description = "4-data output app_secret_id"
}
variable "app_secret_version" {
  type        = string
  default     = ""
  description = "Secret の数値 version（latest は使わない）。空なら APP_CONFIG を渡さない"
  validation {
    condition     = var.app_secret_version == "" || can(regex("^[0-9]+$", var.app_secret_version))
    error_message = "app_secret_version は数値で指定（latest 不可）。"
  }
}
variable "java_tool_options" {
  type    = string
  default = "-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
}
variable "deletion_protection" {
  type    = bool
  default = true
}

# --- Cloud Run（No.4） ---
variable "services" {
  type = map(object({
    image         = string
    paths         = list(string)
    min_instances = number
    max_instances = number
    cpu           = optional(string, "1")
    memory        = optional(string, "1Gi")
    concurrency   = optional(number, 40)
    cdn           = optional(bool, false)
  }))
  description = "機能単位サービス。image は初回のみ使用（以後はアプリ CD が所有）"
  validation {
    condition     = alltrue([for s in var.services : can(regex("@sha256:[a-f0-9]{64}$", s.image))])
    error_message = "image は digest 指定（@sha256:...）にすること。"
  }
}
variable "default_service" {
  type        = string
  description = "URL map の既定ルーティング先（services のキー）"
}
variable "jobs" {
  type = map(object({
    image      = string
    task_count = optional(number, 1)
    parallelism = optional(number, 1)
    timeout    = optional(string, "3600s")
    cpu        = optional(string, "1")
    memory     = optional(string, "2Gi")
  }))
  default = {}
}

# --- 入口（No.3・11） ---
variable "domains" {
  type = list(string)
}
variable "public_site" {
  type    = bool
  default = true
}
variable "allowed_cidrs" {
  type    = list(string)
  default = []
}
variable "waf_preview" {
  type        = bool
  default     = true
  description = "true：WAF をプレビュー（ログのみ）。stg で誤検知を確認後 false"
}
variable "waf_sensitivity" {
  type    = number
  default = 1
}
variable "rl_global_count" {
  type    = number
  default = 600
  description = "IP 単位の全体レート制限（回/60秒）"
}
variable "path_throttles" {
  type = map(object({
    priority = number
    path     = string
    count    = number
  }))
  default     = {}
  description = "パス単位の流量制御（検索・一括ダウンロード等）"
}
variable "recaptcha_enabled" {
  type    = bool
  default = true
}
variable "robots_noindex_paths" {
  type        = list(string)
  default     = []
  description = "X-Robots-Tag を付与するサービスキー（提案書 項番21）"
}
variable "sorry_bucket" {
  type        = string
  description = "1-org output sorry_bucket（大阪）"
}
variable "maintenance_mode" {
  type        = bool
  default     = false
  description = "true で全リクエストを Sorry ページへ切替"
}
variable "model_armor_enabled" {
  type        = bool
  default     = false
  description = "【要検証】provider 6.50.0 で google_model_armor_template が利用可能か確認後に有効化"
}
