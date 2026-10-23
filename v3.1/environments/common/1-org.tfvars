org_id             = "REPLACE_ORG_ID"
billing_account_id = "REPLACE_BILLING_ACCOUNT_ID"
common_folder_id   = "folders/REPLACE"          # 0-bootstrap output
random_suffix      = "a1b2"
executor_sa = {                                 # 0-bootstrap output
  dev  = "im-dev@REPLACE_IAC_PROJECT.iam.gserviceaccount.com"
  stg  = "im-stg@REPLACE_IAC_PROJECT.iam.gserviceaccount.com"
  prod = "im-prod@REPLACE_IAC_PROJECT.iam.gserviceaccount.com"
}
drs_customer_ids    = ["REPLACE_CUSTOMER_ID"]
audit_retention_days = 400
lock_audit_bucket    = false                    # stg 確認後 true（解除不可）
backup_retention_days = 30
lock_backup_buckets   = false                   # stg 確認後 true（解除不可）
backup_admins = ["group:REPLACE_BACKUP_ADMINS@example.jp"]
sorry_editors = ["group:REPLACE_INPIT_STAFF@example.jp"]
# 2巡目：2-environments output backup_writer_members を設定
backup_writers = {
  # dev  = ["serviceAccount:project-NNN@storage-transfer-service.iam.gserviceaccount.com", "serviceAccount:backup-ops@..."]
}
