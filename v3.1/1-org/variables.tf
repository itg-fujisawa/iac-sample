variable "org_id" {
  type = string
}
variable "billing_account_id" {
  type = string
}
variable "common_folder_id" {
  type        = string
  description = "0-bootstrap output: folders/NNN"
}
variable "region" {
  type    = string
  default = "asia-northeast1"
}
variable "dr_region" {
  type    = string
  default = "asia-northeast2"
}
variable "project_prefix" {
  type    = string
  default = "jpp"
}
variable "random_suffix" {
  type = string
}
variable "cost_center" {
  type    = string
  default = "jpp-renewal"
}
variable "executor_sa" {
  type        = map(string)
  description = "0-bootstrap output executor_sa（dev/stg/prod を使用）"
}
variable "drs_customer_ids" {
  type        = list(string)
  description = "iam.allowedPolicyMemberDomains に許可する Workspace/Cloud Identity の顧客ID"
}
variable "enforce_resource_locations" {
  type    = bool
  default = true
}

# --- 監査ログ（No.8）---
variable "audit_retention_days" {
  type    = number
  default = 400
  validation {
    condition     = var.audit_retention_days >= 366
    error_message = "提案書：ログは12か月以上保管（366日以上）。"
  }
}
variable "lock_audit_bucket" {
  type        = bool
  default     = false
  description = "true にすると解除不可。stg で確認後に有効化"
}
variable "audit_viewers" {
  type    = set(string)
  default = []
}

# --- バックアップ（No.2）---
variable "backup_retention_days" {
  type        = number
  default     = 30
  description = "WORM 保持日数（サービス終了まで保管する世代は運用で別管理）"
}
variable "lock_backup_buckets" {
  type        = bool
  default     = false
  description = "true にすると解除不可（WORM）。stg で確認後に prod で有効化"
}
variable "backup_writers" {
  type        = map(set(string))
  default     = {}
  description = "env => 書込み主体（2-environments の出力 backup_writer_members を2巡目で設定）"
}
variable "backup_admins" {
  type        = set(string)
  description = "バックアップ管理者（本番運用者とは別グループ）"
}
variable "enable_backup_vault" {
  type        = bool
  default     = false
  description = "【要検証】provider 6.50.0 の google_backup_dr_backup_vault を確認後に有効化"
}

# --- Sorry ページ（No.11）---
variable "sorry_editors" {
  type        = set(string)
  default     = []
  description = "情報館様職員の緊急更新用グループ（提案書 項番51）"
}
