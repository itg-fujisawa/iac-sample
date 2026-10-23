variable "org_id" {
  type        = string
  description = "組織ID（数値）"
}
variable "billing_account_id" {
  type = string
}
variable "region" {
  type    = string
  default = "asia-northeast1"
}
variable "project_prefix" {
  type    = string
  default = "jpp"
}
variable "random_suffix" {
  type        = string
  description = "Project ID の一意性確保用（4〜6桁の英数小文字）"
  validation {
    condition     = can(regex("^[a-z0-9]{4,6}$", var.random_suffix))
    error_message = "random_suffix must be 4-6 lowercase alphanumerics."
  }
}
variable "iac_admins" {
  type        = set(string)
  description = "基盤管理者グループ（group:xxx@example.jp）。Infra Manager の Preview/Deploy 実行者"
}
variable "cost_center" {
  type    = string
  default = "jpp-renewal"
}
