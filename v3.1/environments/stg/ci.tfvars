project_id  = "REPLACE_STG_PROJECT"
environment = "stg"
ci_sa       = "im-ci@REPLACE_IAC_PROJECT.iam.gserviceaccount.com"
service_accounts = {
  app-builder = "app-builder@REPLACE_STG_PROJECT.iam.gserviceaccount.com"
  batch-job   = "batch-job@REPLACE_STG_PROJECT.iam.gserviceaccount.com"
  app-runtime = "app-runtime@REPLACE_STG_PROJECT.iam.gserviceaccount.com"
}
exempt_images = []
deployers     = ["group:REPLACE_APP_DEPLOYERS@example.jp"]
promote_readers = ["serviceAccount:app-builder@REPLACE_PROD_PROJECT.iam.gserviceaccount.com"]
