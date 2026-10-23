project_id   = "REPLACE_STG_PROJECT"
environment  = "stg"
alert_emails = ["REPLACE_OPS@example.jp"]
services = {                                  # 5-app-infra output services
  common-api = "jpp-stg-common-api"
  tokujitsu  = "jpp-stg-tokujitsu"
  isho       = "jpp-stg-isho"
  shohyo     = "jpp-stg-shohyo"
  shimpan    = "jpp-stg-shimpan"
}
uptime_host = "REPLACE_stg.example.go.jp"
scc_notification_enabled = true
ops_vm_enabled = true
ops_subnet     = "projects/REPLACE_STG_PROJECT/regions/asia-northeast1/subnetworks/jpp-stg-ops"
service_accounts = {
  ops-vm = "ops-vm@REPLACE_STG_PROJECT.iam.gserviceaccount.com"
}
