resource "google_cloud_run_v2_job" "migrate" {
  name     = "bandstand-migrate"
  location = var.region

  template {
    template {
      service_account = google_service_account.api_runtime.email
      timeout         = "1800s"
      max_retries     = 0

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.postgres.connection_name]
        }
      }

      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/bandstand/api:${var.image_tag}"
        args  = ["migrate"]

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
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_service.run,
    google_project_service.sqladmin,
  ]
}
