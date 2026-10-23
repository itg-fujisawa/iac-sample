variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be dev, stg or prod."
  }
}
variable "region" {
  type    = string
  default = "asia-northeast1"
}
variable "env_folder_id" {
  type        = string
  description = "1-org output env_folder_ids[env]"
}
variable "billing_account_id" {
  type = string
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
variable "budget_amount" {
  type        = number
  description = "月額予算（円）。stg/prod は 0 不可（No.10）"
  validation {
    condition     = var.budget_amount >= 0
    error_message = "budget_amount must be >= 0."
  }
}
variable "budget_emails" {
  type        = list(string)
  default     = []
  description = "予算通知先メール。budget_amount > 0 の場合は必須"
}
variable "scc_viewer_members" {
  type    = set(string)
  default = []
  validation {
    condition     = alltrue([for m in var.scc_viewer_members : can(regex("^(user|group|serviceAccount):[^ @]+@[^ @]+$", m))])
    error_message = "Specify explicit identities; public principals are prohibited."
  }
}
