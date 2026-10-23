# No.5：Model Armor（生成AI 入出力の保護）【要検証】
# provider 6.50.0 に google_model_armor_template が無い場合は model_armor_enabled=false のまま、
# gcloud model-armor templates create で作成し、後続版で import する。
resource "google_model_armor_template" "default" {
  count       = var.model_armor_enabled ? 1 : 0
  project     = var.project_id
  location    = var.region
  template_id = "${local.name}-guard"
  labels      = local.labels
  filter_config {
    pi_and_jailbreak_filter_settings {
      filter_enforcement = "ENABLED"
      confidence_level   = "MEDIUM_AND_ABOVE"
    }
    malicious_uri_filter_settings {
      filter_enforcement = "ENABLED"
    }
  }
}
