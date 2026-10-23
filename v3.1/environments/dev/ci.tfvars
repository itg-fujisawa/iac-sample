project_id  = "REPLACE_DEV_PROJECT"
environment = "dev"
ci_sa       = "im-ci@REPLACE_IAC_PROJECT.iam.gserviceaccount.com"
service_accounts = {
  app-builder = "app-builder@REPLACE_DEV_PROJECT.iam.gserviceaccount.com"
  batch-job   = "batch-job@REPLACE_DEV_PROJECT.iam.gserviceaccount.com"
  app-runtime = "app-runtime@REPLACE_DEV_PROJECT.iam.gserviceaccount.com"
}
exempt_images = []
deployers     = ["group:REPLACE_APP_DEPLOYERS@example.jp"]
