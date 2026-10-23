project_id  = "REPLACE_DEV_PROJECT"   # 2-environments output
environment = "dev"
subnets = {
  app       = { cidr = "10.10.0.0/22", purpose = "Cloud Run Direct VPC egress" }
  batch     = { cidr = "10.10.4.0/23", purpose = "Cloud Run Jobs / Dataflow" }
  ops       = { cidr = "10.10.6.0/24", purpose = "運用管理 VM" }
  migration = { cidr = "10.10.7.0/24", purpose = "Cloud Batch（データ移行）" }
}
psa_address          = "10.10.128.0"
psa_prefix_length    = 17
nat_enabled          = true
interconnect_enabled = false   # dev は外部接続不可（check で強制）
dr_mode              = "cold"
egress_allow_rules = {
  # 外部接続調整表から生成（接続先・方式・期限・窓口は調整表で管理）
  # jpo-gw = { priority = 2000, dest_ranges = ["192.0.2.0/24"], protocol = "tcp", ports = ["443"], description = "特許庁 連携GW" }
}
