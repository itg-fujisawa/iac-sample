# No.1・2：大阪保管・WORM・本番と別権限（prj-common-backup）
resource "google_storage_bucket" "backup" {
  for_each                    = local.envs
  project                     = google_project.common["backup"].project_id
  name                        = "${google_project.common["backup"].project_id}-${each.key}"
  location                    = var.dr_region
  storage_class               = "NEARLINE"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = merge(local.labels, { env = each.key, purpose = "backup" })
  versioning {
    enabled = true
  }
  retention_policy {
    retention_period = var.backup_retention_days * 86400
    is_locked        = var.lock_backup_buckets
  }
  lifecycle {
    prevent_destroy = true
  }
  depends_on = [google_project_service.common]
}

# 書込みは各環境の転送・エクスポート主体のみ（削除権限なし）
resource "google_storage_bucket_iam_member" "backup_writer" {
  for_each = {
    for p in flatten([for env, members in var.backup_writers : [for m in members : { env = env, member = m }]]) : "${p.env}|${p.member}" => p
  }
  bucket = google_storage_bucket.backup[each.value.env].name
  role   = "roles/storage.objectCreator"
  member = each.value.member
}
resource "google_storage_bucket_iam_member" "backup_writer_list" {
  for_each = {
    for p in flatten([for env, members in var.backup_writers : [for m in members : { env = env, member = m }]]) : "${p.env}|${p.member}" => p
  }
  bucket = google_storage_bucket.backup[each.value.env].name
  role   = "roles/storage.legacyBucketReader"
  member = each.value.member
}

resource "google_project_iam_member" "backup_admin" {
  for_each = var.backup_admins
  project  = google_project.common["backup"].project_id
  role     = "roles/storage.admin"
  member   = each.value
}

# 【要検証】Backup and DR ボールト（最小保持期間を強制）
resource "google_backup_dr_backup_vault" "osaka" {
  count                                      = var.enable_backup_vault ? 1 : 0
  project                                    = google_project.common["backup"].project_id
  location                                   = var.dr_region
  backup_vault_id                            = "jpp-vault-osaka"
  backup_minimum_enforced_retention_duration = "${var.backup_retention_days * 86400}s"
  labels                                     = local.labels
  depends_on                                 = [google_project_service.common]
}
