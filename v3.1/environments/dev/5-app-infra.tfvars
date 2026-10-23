project_id  = "REPLACE_DEV_PROJECT"
environment = "dev"
network     = "projects/REPLACE_DEV_PROJECT/global/networks/jpp-dev-vpc"
subnets = {
  app   = "projects/REPLACE_DEV_PROJECT/regions/asia-northeast1/subnetworks/jpp-dev-app"
  batch = "projects/REPLACE_DEV_PROJECT/regions/asia-northeast1/subnetworks/jpp-dev-batch"
}
service_accounts = {
  app-runtime = "app-runtime@REPLACE_DEV_PROJECT.iam.gserviceaccount.com"
  batch-job   = "batch-job@REPLACE_DEV_PROJECT.iam.gserviceaccount.com"
}
sql_connection_name = "REPLACE_DEV_PROJECT:asia-northeast1:jpp-dev-pg"
spanner_database    = "projects/REPLACE_DEV_PROJECT/instances/jpp-dev-search/databases/patent-search"
redis_host          = "REPLACE"

# 機能単位サービス。image は scripts/app_build.sh が digest を書き込む（以後はアプリ CD が更新）
default_service = "common-api"
services = {
  common-api = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", paths = ["/api/*"], min_instances = 0, max_instances = 20 }
  tokujitsu  = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", paths = ["/p/*"], min_instances = 0, max_instances = 50 }
  isho       = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", paths = ["/d/*"], min_instances = 0, max_instances = 20 }
  shohyo     = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", paths = ["/t/*"], min_instances = 0, max_instances = 30 }
  shimpan    = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", paths = ["/s/*"], min_instances = 0, max_instances = 10 }
  static     = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", paths = ["/static/*"], min_instances = 0, max_instances = 10, cdn = true }
}
jobs = {
  daily-load = { image = "asia-northeast1-docker.pkg.dev/REPLACE/jpp-dev-app/app@sha256:0000000000000000000000000000000000000000000000000000000000000000", task_count = 1, timeout = "10800s" }
}

domains              = ["REPLACE_dev.example.go.jp"]
public_site          = false
allowed_cidrs        = ["REPLACE_OFFICE_CIDR/32"]
waf_preview          = true     # prod は false 必須（check）
rl_global_count      = 600
path_throttles = {
  search   = { priority = 4000, path = "/api/search", count = 120 }
  download = { priority = 4001, path = "/api/download", count = 30 }
}
recaptcha_enabled    = true
robots_noindex_paths = ["common-api"]
sorry_bucket         = "REPLACE_COMMON_SORRY_PROJECT-sorry"   # 1-org output
maintenance_mode     = false
model_armor_enabled  = false   # 【要検証】
# アプリ（app/ Spring Boot）
db_name              = "patent"
db_pool_max          = 5
app_secret_id        = "jpp-dev-app-config"   # 4-data output
app_secret_version   = ""                     # Secret 登録後に数値 version（例 "1"）
deletion_protection  = false
