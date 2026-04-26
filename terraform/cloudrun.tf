resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "api" {
  location      = var.region
  repository_id = "bandstand"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}

resource "google_cloud_run_v2_service" "api" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.api_runtime.email
    timeout         = "30s"

    scaling {
      min_instance_count = 0
      max_instance_count = 4
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.postgres.connection_name]
      }
    }

    containers {
      image = "us-central1-docker.pkg.dev/${var.project_id}/bandstand/api:${var.image_tag}"

      ports {
        container_port = 8080
      }

      env {
        name  = "RACK_ENV"
        value = "production"
      }

      env {
        name  = "LOG_LEVEL"
        value = "info"
      }

      env {
        name  = "DB_USER"
        value = "bandstand_app"
      }

      env {
        name  = "DB_NAME"
        value = "bandstand"
      }

      env {
        name  = "DB_SOCKET_DIR"
        value = "/cloudsql/${google_sql_database_instance.postgres.connection_name}"
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 5
        period_seconds        = 5
        failure_threshold     = 6
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
        period_seconds = 30
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }
  }

  depends_on = [
    google_project_service.run,
    google_project_service.sqladmin,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  name     = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
