# No.7：Binary Authorization（ビルド来歴の署名がないイメージは prod/stg で起動不可）
resource "google_kms_key_ring" "attest" {
  project  = var.project_id
  name     = "${local.name}-attest"
  location = var.region
}

resource "google_kms_crypto_key" "attest" {
  name     = "build-attestor"
  key_ring = google_kms_key_ring.attest.id
  purpose  = "ASYMMETRIC_SIGN"
  labels   = local.labels
  version_template {
    algorithm        = "EC_SIGN_P256_SHA256"
    protection_level = "SOFTWARE"
  }
  lifecycle {
    prevent_destroy = true
  }
}

data "google_kms_crypto_key_version" "attest" {
  crypto_key = google_kms_crypto_key.attest.id
}

resource "google_container_analysis_note" "build" {
  project = var.project_id
  name    = "${local.name}-build-note"
  attestation_authority {
    hint {
      human_readable_name = "${local.name} Cloud Build attestor"
    }
  }
}

resource "google_binary_authorization_attestor" "build" {
  project = var.project_id
  name    = "${local.name}-build"
  attestation_authority_note {
    note_reference = google_container_analysis_note.build.name
    public_keys {
      id = data.google_kms_crypto_key_version.attest.id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.attest.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.attest.public_key[0].algorithm
      }
    }
  }
}

resource "google_binary_authorization_policy" "policy" {
  project                       = var.project_id
  global_policy_evaluation_mode = "ENABLE"

  dynamic "admission_whitelist_patterns" {
    for_each = var.exempt_images
    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }

  default_admission_rule {
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = var.environment == "dev" ? "DRYRUN_AUDIT_LOG_ONLY" : "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.build.name]
  }
}

# 署名者：app-builder（Cloud Build）
resource "google_kms_crypto_key_iam_member" "signer" {
  crypto_key_id = google_kms_crypto_key.attest.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.service_accounts["app-builder"]}"
}
resource "google_container_analysis_note_iam_member" "attacher" {
  project = var.project_id
  note    = google_container_analysis_note.build.name
  role    = "roles/containeranalysis.notes.attacher"
  member  = "serviceAccount:${var.service_accounts["app-builder"]}"
}
resource "google_binary_authorization_attestor_iam_member" "viewer" {
  project  = var.project_id
  attestor = google_binary_authorization_attestor.build.name
  role     = "roles/binaryauthorization.attestorsViewer"
  member   = "serviceAccount:${var.service_accounts["app-builder"]}"
}
# アプリ CD：Cloud Run のイメージ更新
resource "google_project_iam_member" "builder_deploy" {
  for_each = toset(["roles/run.developer"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${var.service_accounts["app-builder"]}"
}
resource "google_service_account_iam_member" "builder_actas_runtime" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_accounts["app-runtime"]}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.service_accounts["app-builder"]}"
}
