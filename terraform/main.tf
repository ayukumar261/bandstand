terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "gcs" {
    bucket = "bandstand-494122-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "bandstand-494122"
  region  = "us-central1"
}

resource "google_sql_database_instance" "postgres" {
  name             = "bandstand-postgres"
  database_version = "POSTGRES_16"
  region           = "us-central1"

  settings {
    tier              = "db-f1-micro"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false
}

resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_sql_database" "bandstand" {
  name     = "bandstand"
  instance = google_sql_database_instance.postgres.name
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$&*()-_=+[]{}<>"
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "bandstand-db-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_sql_user" "bandstand_app" {
  name     = "bandstand_app"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}
