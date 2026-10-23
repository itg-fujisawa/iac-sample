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

variable "alert_emails" {
  type = list(string)
  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "alert_emails is required."
  }
}
variable "services" {
  type        = map(string)
  description = "5-app-infra output services（キー => Cloud Run サービス名）"
}
variable "uptime_host" {
  type    = string
  default = ""
}
variable "latency_threshold_ms" {
  type    = number
  default = 2000
}
variable "scc_notification_enabled" {
  type    = bool
  default = true
}
variable "scc_filter" {
  type    = string
  default = "state=\"ACTIVE\" AND (severity=\"HIGH\" OR severity=\"CRITICAL\")"
}

# 運用管理 VM（No.5：Compute Engine、複数ゾーン MIG・自動修復）
variable "ops_vm_enabled" {
  type    = bool
  default = true
}
variable "ops_vm_count" {
  type    = number
  default = 2
}
variable "ops_machine_type" {
  type    = string
  default = "e2-standard-2"
}
variable "ops_subnet" {
  type    = string
  default = ""
  description = "3-network output subnets[\"ops\"]"
}
variable "service_accounts" {
  type = map(string)
}
