# No.10：予算アラート必須化
resource "google_monitoring_notification_channel" "budget" {
  for_each     = toset(var.budget_emails)
  project      = google_project.workload.project_id
  display_name = "budget-${each.value}"
  type         = "email"
  labels = {
    email_address = each.value
  }
  depends_on = [google_project_service.apis]
}

resource "google_billing_budget" "budget" {
  count           = var.budget_amount > 0 ? 1 : 0
  billing_account = var.billing_account_id
  display_name    = "jpp-${var.environment}-monthly"
  budget_filter {
    projects = ["projects/${google_project.workload.number}"]
  }
  amount {
    specified_amount {
      currency_code = "JPY"
      units         = tostring(var.budget_amount)
    }
  }
  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }
  all_updates_rule {
    monitoring_notification_channels = [for c in google_monitoring_notification_channel.budget : c.id]
    disable_default_iam_recipients   = false
  }
  lifecycle {
    precondition {
      condition     = length(var.budget_emails) > 0
      error_message = "budget_emails is required when budget_amount > 0."
    }
  }
}

check "budget_required" {
  assert {
    condition     = var.environment == "dev" || var.budget_amount > 0
    error_message = "stg/prod は budget_amount > 0 が必須（提案書 項番17）。予算超過は自動停止しない点にも注意。"
  }
}
