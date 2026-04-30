variable "project_id" {
  type    = string
  default = "bandstand-494122"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "image_tag" {
  type = string
}

variable "service_name" {
  type    = string
  default = "bandstand-api"
}

variable "github_repo" {
  type    = string
  default = "ayukumar261/bandstand"
}

variable "billing_account_id" {
  type        = string
  description = "GCP billing account ID for budget alerts (e.g., 01XXXX-XXXXXX-XXXXXX). Find with `gcloud billing accounts list`."
}

variable "notification_email" {
  type        = string
  default     = "ayukumar261@gmail.com"
  description = "Email address to receive budget alert notifications."
}

variable "monthly_budget_usd" {
  type        = number
  default     = 15
  description = "Monthly spend ceiling in USD. Email alerts fire at 50/75/90/100/120% of this amount."
}
