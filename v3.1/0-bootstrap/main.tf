locals {
  labels = {
    system      = "jpp"
    env         = "common"
    stage       = "0-bootstrap"
    managed-by  = "terraform-bootstrap"
    cost-center = var.cost_center
  }
  # 実行SA：1-org 用と環境別（prod を dev/stg から分離）
  executors = {
    org  = "Infra Manager executor for 1-org"
    dev  = "Infra Manager executor for dev (2-6, ci)"
    stg  = "Infra Manager executor for stg (2-6, ci)"
    prod = "Infra Manager executor for prod (2-6, ci)"
  }
  iac_apis = [
    "config.googleapis.com", "cloudbuild.googleapis.com", "iam.googleapis.com",
    "iamcredentials.googleapis.com", "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com", "serviceusage.googleapis.com", "storage.googleapis.com",
    "orgpolicy.googleapis.com", "logging.googleapis.com", "billingbudgets.googleapis.com",
    "securitycenter.googleapis.com", "artifactregistry.googleapis.com",
  ]
}

# fld-common：共通（IaC・監査・バックアップ・Sorry）を配置。環境フォルダは 1-org が作成
resource "google_folder" "common" {
  display_name = "fld-common"
  parent       = "organizations/${var.org_id}"
}

resource "google_project" "iac" {
  name            = "prj-common-iac"
  project_id      = "${var.project_prefix}-common-iac-${var.random_suffix}"
  folder_id       = google_folder.common.name
  billing_account = var.billing_account_id
  labels          = local.labels
  auto_create_network = false
  deletion_policy = "PREVENT"
}

resource "google_project_service" "iac" {
  for_each           = toset(local.iac_apis)
  project            = google_project.iac.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "executor" {
  for_each     = local.executors
  project      = google_project.iac.project_id
  account_id   = "im-${each.key}"
  display_name = each.value
}

# Infra Manager の実行に必要な最小権限（管理 Project 内）
resource "google_project_iam_member" "executor_agent" {
  for_each = google_service_account.executor
  project  = google_project.iac.project_id
  role     = "roles/config.agent"
  member   = "serviceAccount:${each.value.email}"
}

# CI（Cloud Build）用 SA：Preview/Deploy 呼出しと executor の actAs
resource "google_service_account" "ci" {
  project      = google_project.iac.project_id
  account_id   = "im-ci"
  display_name = "Cloud Build caller for Infra Manager"
}
resource "google_project_iam_member" "ci" {
  for_each = toset(["roles/config.admin", "roles/cloudbuild.builds.builder", "roles/logging.logWriter"])
  project  = google_project.iac.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci.email}"
}
resource "google_service_account_iam_member" "ci_actas" {
  for_each           = google_service_account.executor
  service_account_id = each.value.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ci.email}"
}

# 基盤管理者：Preview/Deploy を実行できる。prod の Deploy は CI 承認経由を運用で強制
resource "google_project_iam_member" "admins" {
  for_each = var.iac_admins
  project  = google_project.iac.project_id
  role     = "roles/config.admin"
  member   = each.value
}
resource "google_service_account_iam_member" "admins_actas" {
  for_each = {
    for p in setproduct(keys(local.executors), tolist(var.iac_admins)) : "${p[0]}|${p[1]}" => { sa = p[0], member = p[1] }
  }
  service_account_id = google_service_account.executor[each.value.sa].name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value.member
}

# 1-org 実行SAへの組織権限
resource "google_organization_iam_member" "org_executor" {
  for_each = toset([
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/orgpolicy.policyAdmin",
    "roles/logging.configWriter",
    "roles/iam.securityAdmin",
    "roles/securitycenter.notificationConfigEditor",
  ])
  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.executor["org"].email}"
}
resource "google_billing_account_iam_member" "org_executor" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.executor["org"].email}"
}
# 環境別 executor：課金紐付けと予算作成（フォルダ権限は 1-org が付与）
resource "google_billing_account_iam_member" "env_executor" {
  for_each = {
    for p in setproduct(["dev", "stg", "prod"], ["roles/billing.user", "roles/billing.costsManager"]) : "${p[0]}|${p[1]}" => { env = p[0], role = p[1] }
  }
  billing_account_id = var.billing_account_id
  role               = each.value.role
  member             = "serviceAccount:${google_service_account.executor[each.value.env].email}"
}

# 0-bootstrap 自身の State と、ソース／証跡バケット
resource "google_storage_bucket" "state" {
  project                     = google_project.iac.project_id
  name                        = "${google_project.iac.project_id}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  labels = local.labels
  lifecycle {
    prevent_destroy = true
  }
}
resource "google_storage_bucket" "evidence" {
  project                     = google_project.iac.project_id
  name                        = "${google_project.iac.project_id}-evidence"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  labels = local.labels
}
resource "google_storage_bucket_iam_member" "evidence" {
  for_each = toset(concat(["serviceAccount:${google_service_account.ci.email}"], tolist(var.iac_admins)))
  bucket   = google_storage_bucket.evidence.name
  role     = "roles/storage.objectCreator"
  member   = each.value
}
