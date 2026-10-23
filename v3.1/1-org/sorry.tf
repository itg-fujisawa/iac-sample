# No.11：東京リージョン外（大阪）の Sorry ページ。環境 Project の障害から独立させる
resource "google_storage_bucket" "sorry" {
  project                     = google_project.common["sorry"].project_id
  name                        = "${google_project.common["sorry"].project_id}-sorry"
  location                    = var.dr_region
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
  labels                      = merge(local.labels, { purpose = "sorry" })
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
  depends_on = [google_org_policy_policy.pap_sorry_exception, google_project_service.common]
}

resource "google_storage_bucket_iam_member" "sorry_public" {
  bucket     = google_storage_bucket.sorry.name
  role       = "roles/storage.objectViewer"
  member     = "allUsers"
  depends_on = [google_org_policy_policy.drs_sorry_exception]
}

# 情報館様職員による緊急更新（提案書 項番51）
resource "google_storage_bucket_iam_member" "sorry_editor" {
  for_each = var.sorry_editors
  bucket   = google_storage_bucket.sorry.name
  role     = "roles/storage.objectAdmin"
  member   = each.value
}

resource "google_storage_bucket_object" "sorry_index" {
  bucket       = google_storage_bucket.sorry.name
  name         = "index.html"
  source       = "${path.module}/sorry/index.html"
  content_type = "text/html; charset=utf-8"
  cache_control = "no-store"
  lifecycle {
    ignore_changes = [source, detect_md5hash] # 職員による更新を上書きしない
  }
}
