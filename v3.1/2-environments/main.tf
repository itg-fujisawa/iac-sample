locals {
  labels = {
    system      = "jpp"
    env         = var.environment
    stage       = "2-environments"
    managed-by  = "infra-manager"
    cost-center = var.cost_center
  }
  # No.5・7：提案書の構成要素に必要な API を網羅
  apis = [
    "compute.googleapis.com", "run.googleapis.com", "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com", "sqladmin.googleapis.com", "servicenetworking.googleapis.com",
    "cloudbuild.googleapis.com", "logging.googleapis.com", "monitoring.googleapis.com",
    "dns.googleapis.com", "iam.googleapis.com", "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com", "storage.googleapis.com", "cloudresourcemanager.googleapis.com",
    "spanner.googleapis.com", "redis.googleapis.com", "file.googleapis.com",
    "batch.googleapis.com", "aiplatform.googleapis.com", "discoveryengine.googleapis.com",
    "modelarmor.googleapis.com", "recaptchaenterprise.googleapis.com",
    "binaryauthorization.googleapis.com", "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com", "cloudkms.googleapis.com",
    "storagetransfer.googleapis.com", "cloudscheduler.googleapis.com", "dataflow.googleapis.com",
    "bigquery.googleapis.com", "securitycenter.googleapis.com", "pubsub.googleapis.com",
    "networkconnectivity.googleapis.com", "billingbudgets.googleapis.com",
  ]
  # 実行用 SA（用途別に分離）
  service_accounts = {
    app-runtime = "Cloud Run 実行"
    app-builder = "コンテナビルド"
    batch-job   = "Cloud Run Jobs（定時処理）"
    mig-batch   = "Cloud Batch（データ移行）"
    indexer     = "Spanner 検索同期"
    backup-ops  = "バックアップ転送・エクスポート"
    ops-vm      = "運用管理 VM"
  }
  sa_roles = {
    app-runtime = ["roles/cloudsql.client", "roles/cloudsql.instanceUser", "roles/logging.logWriter", "roles/monitoring.metricWriter", "roles/cloudtrace.agent"]
    app-builder = ["roles/logging.logWriter", "roles/artifactregistry.writer", "roles/containeranalysis.notes.attacher"]
    batch-job   = ["roles/cloudsql.client", "roles/cloudsql.instanceUser", "roles/logging.logWriter", "roles/monitoring.metricWriter"]
    mig-batch   = ["roles/batch.agentReporter", "roles/logging.logWriter", "roles/cloudsql.client", "roles/cloudsql.instanceUser"]
    indexer     = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
    backup-ops  = ["roles/dataflow.worker", "roles/dataflow.developer", "roles/logging.logWriter", "roles/spanner.databaseReader"]
    ops-vm      = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
  }
}

resource "google_project" "workload" {
  name                = "prj-${var.environment}-patent"
  project_id          = "${var.project_prefix}-${var.environment}-patent-${var.random_suffix}"
  folder_id           = var.env_folder_id
  billing_account     = var.billing_account_id
  auto_create_network = false
  labels              = local.labels
  deletion_policy     = var.environment == "prod" ? "PREVENT" : "DELETE"
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  project            = google_project.workload.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "sa" {
  for_each     = local.service_accounts
  project      = google_project.workload.project_id
  account_id   = each.key
  display_name = each.value
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "sa" {
  for_each = {
    for p in flatten([for sa, roles in local.sa_roles : [for r in roles : { sa = sa, role = r }]]) : "${p.sa}|${p.role}" => p
  }
  project = google_project.workload.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.sa[each.value.sa].email}"
}

# 監査ログ（Secret / KMS の DATA_READ）
resource "google_project_iam_audit_config" "data_access" {
  for_each = toset(["secretmanager.googleapis.com", "cloudkms.googleapis.com", "spanner.googleapis.com", "cloudsql.googleapis.com"])
  project  = google_project.workload.project_id
  service  = each.value
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# SCC 閲覧（ティアの有効化は組織側で Premium を設定。No.7）
resource "google_project_iam_member" "scc_viewer" {
  for_each = var.scc_viewer_members
  project  = google_project.workload.project_id
  role     = "roles/securitycenter.adminViewer"
  member   = each.value
}

data "google_storage_transfer_project_service_account" "sts" {
  project    = google_project.workload.project_id
  depends_on = [google_project_service.apis]
}
