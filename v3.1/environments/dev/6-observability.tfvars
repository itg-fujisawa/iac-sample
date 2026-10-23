project_id   = "REPLACE_DEV_PROJECT"
environment  = "dev"
alert_emails = ["REPLACE_OPS@example.jp"]
services = {                                  # 5-app-infra output services
  common-api = "jpp-dev-common-api"
  tokujitsu  = "jpp-dev-tokujitsu"
  isho       = "jpp-dev-isho"
  shohyo     = "jpp-dev-shohyo"
  shimpan    = "jpp-dev-shimpan"
}
uptime_host = "REPLACE_dev.example.go.jp"
scc_notification_enabled = true
ops_vm_enabled = false
ops_subnet     = "projects/REPLACE_DEV_PROJECT/regions/asia-northeast1/subnetworks/jpp-dev-ops"
service_accounts = {
  ops-vm = "ops-vm@REPLACE_DEV_PROJECT.iam.gserviceaccount.com"
}
