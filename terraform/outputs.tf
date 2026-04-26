output "api_url" {
  value = google_cloud_run_v2_service.api.uri
}

output "github_actions_workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_ci_service_account" {
  value = google_service_account.ci.email
}
