locals {
  envs = toset(["dev", "stg", "prod"])
  labels = {
    system      = "jpp"
    env         = "common"
    stage       = "1-org"
    managed-by  = "infra-manager"
    cost-center = var.cost_center
  }
  # 環境 executor に環境フォルダ単位で与える権限（Owner/Editor は付与しない）
  env_folder_roles = [
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/compute.admin",
    "roles/run.admin",
    "roles/cloudsql.admin",
    "roles/spanner.admin",
    "roles/redis.admin",
    "roles/file.editor",
    "roles/storage.admin",
    "roles/secretmanager.admin",
    "roles/artifactregistry.admin",
    "roles/servicenetworking.networksAdmin",
    "roles/monitoring.admin",
    "roles/logging.configWriter",
    "roles/dns.admin",
    "roles/cloudkms.admin",
    "roles/binaryauthorization.policyEditor",
    "roles/binaryauthorization.attestorsAdmin",
    "roles/containeranalysis.notes.editor",
    "roles/recaptchaenterprise.admin",
    "roles/cloudscheduler.admin",
    "roles/pubsub.admin",
    "roles/securitycenter.notificationConfigEditor",
  ]
}

# ---------- フォルダ（fld-mig は作らない：提案書どおり移行環境なし） ----------
resource "google_folder" "env" {
  for_each     = local.envs
  display_name = "fld-${each.key}"
  parent       = "organizations/${var.org_id}"
}

resource "google_folder_iam_member" "env_executor" {
  for_each = {
    for p in setproduct(tolist(local.envs), local.env_folder_roles) : "${p[0]}|${p[1]}" => { env = p[0], role = p[1] }
  }
  folder = google_folder.env[each.value.env].name
  role   = each.value.role
  member = "serviceAccount:${var.executor_sa[each.value.env]}"
}

# ---------- 共通 Project（fld-common 配下） ----------
resource "google_project" "common" {
  for_each            = toset(["audit", "backup", "sorry"])
  name                = "prj-common-${each.key}"
  project_id          = "${var.project_prefix}-common-${each.key}-${var.random_suffix}"
  folder_id           = var.common_folder_id
  billing_account     = var.billing_account_id
  auto_create_network = false
  labels              = merge(local.labels, { purpose = each.key })
  deletion_policy     = "PREVENT"
}

resource "google_project_service" "common" {
  for_each = {
    for p in setproduct(["audit", "backup", "sorry"], ["logging.googleapis.com", "storage.googleapis.com", "bigquery.googleapis.com", "backupdr.googleapis.com"]) : "${p[0]}|${p[1]}" => { prj = p[0], api = p[1] }
  }
  project            = google_project.common[each.value.prj].project_id
  service            = each.value.api
  disable_on_destroy = false
}
