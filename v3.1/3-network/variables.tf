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

variable "subnets" {
  type = map(object({
    cidr    = string
    purpose = string
  }))
  description = "用途別サブネット（No.6）。例：app / batch / ops / migration"
  validation {
    condition     = contains(keys(var.subnets), "app")
    error_message = "subnets must include 'app'."
  }
}
variable "psa_address" {
  type        = string
  description = "PSA（Cloud SQL / Memorystore / Filestore）予約レンジの先頭アドレス"
}
variable "psa_prefix_length" {
  type    = number
  default = 16
}
variable "nat_enabled" {
  type    = bool
  default = false
}
variable "egress_allow_rules" {
  type = map(object({
    priority    = number
    dest_ranges = list(string)
    protocol    = string
    ports       = list(string)
    description = string
  }))
  default     = {}
  description = "外部接続調整表（接続先・方式・ポート）から生成する許可ルール"
}
variable "interconnect_enabled" {
  type        = bool
  default     = false
  description = "特許庁等との閉域接続（Partner Interconnect）。dev は false（外部接続不可）"
}
variable "interconnect_mtu" {
  type    = number
  default = 1500
}
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
variable "dr_subnet_cidr" {
  type    = string
  default = ""
}
