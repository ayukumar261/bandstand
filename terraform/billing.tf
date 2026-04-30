resource "google_project_service" "billingbudgets" {
  service            = "billingbudgets.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_notification_channel" "cost_alert_email" {
  display_name = "Bandstand cost alert"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account_id
  display_name    = "bandstand-cost-alert"

  budget_filter {
    projects = ["projects/${data.google_project.project.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.monthly_budget_usd
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.75
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  threshold_rules {
    threshold_percent = 1.2
  }

  all_updates_rule {
    monitoring_notification_channels = [
      google_monitoring_notification_channel.cost_alert_email.id,
    ]
  }

  depends_on = [google_project_service.billingbudgets]
}
