# Cloud SQL Module — PostgreSQL for payment platform
# High availability in prod, single instance in dev/staging
resource "google_sql_database_instance" "payments_db" {
  name             = "${var.project_name}-postgres-${var.environment}"
  database_version = "POSTGRES_14"
  region           = var.region
  project          = var.project_id

  deletion_protection = var.environment == "prod" ? true : false

  settings {
    tier              = var.db_tier
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"

    # No public IP — only accessible from within VPC
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
      }
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }

    maintenance_window {
      day  = 7
      hour = 3
    }
  }
}

resource "google_sql_database" "transactions_db" {
  name     = "transactions_db"
  instance = google_sql_database_instance.payments_db.name
  project  = var.project_id
}

resource "google_sql_database" "accounts_db" {
  name     = "accounts_db"
  instance = google_sql_database_instance.payments_db.name
  project  = var.project_id
}

# DB user — password stored in Secret Manager, not here
resource "google_sql_user" "payments_app" {
  name     = "payments_app"
  instance = google_sql_database_instance.payments_db.name
  password = data.google_secret_manager_secret_version.db_password.secret_data
  project  = var.project_id
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = "${var.project_name}-db-password-${var.environment}"
  project = var.project_id
}
