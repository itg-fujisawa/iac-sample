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

variable "service_accounts" {
  type        = map(string)
  description = "2-environments output service_accounts（app-builder が署名）"
}
variable "ci_sa" {
  type        = string
  description = "0-bootstrap output ci_sa"
}
variable "exempt_images" {
  type        = list(string)
  default     = []
  description = "検証対象外イメージ（Google 提供イメージ等）"
}
variable "deployers" {
  type        = set(string)
  default     = []
  description = "scripts/app_build.sh を実行できる担当（group:...）。Cloud Build 起動と app-builder の actAs"
}
variable "promote_readers" {
  type        = set(string)
  default     = []
  description = "このRegistryからイメージをコピーできる主体（stg に prod の app-builder を設定）"
}
