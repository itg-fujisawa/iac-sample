project_id   = "REPLACE_PROD_PROJECT"
environment  = "prod"
alert_emails = ["REPLACE_OPS@example.jp"]
services = {                                  # 5-app-infra output services
  common-api = "jpp-prod-common-api"
  tokujitsu  = "jpp-prod-tokujitsu"
  isho       = "jpp-prod-isho"
  shohyo     = "jpp-prod-shohyo"
  shimpan    = "jpp-prod-shimpan"
}
uptime_host = "REPLACE_prod.example.go.jp"
scc_notification_enabled = true
ops_vm_enabled = true
ops_subnet     = "projects/REPLACE_PROD_PROJECT/regions/asia-northeast1/subnetworks/jpp-prod-ops"
service_accounts = {
  ops-vm = "ops-vm@REPLACE_PROD_PROJECT.iam.gserviceaccount.com"
}
