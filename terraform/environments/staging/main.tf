# Staging Environment — mirrors prod config with smaller sizing
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google"; version = "~> 5.0" }
  }
  backend "gcs" {
    bucket = "payments-tfstate-staging"
    prefix = "terraform/state/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source       = "../../modules/vpc"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = "staging"
  region       = var.region
}

module "gke" {
  source             = "../../modules/gke"
  project_id         = var.project_id
  project_name       = var.project_name
  environment        = "staging"
  region             = var.region
  vpc_name           = module.vpc.vpc_name
  gke_subnet_name    = module.vpc.gke_subnet_name
  machine_type       = "e2-standard-4"
  node_count         = 2
  enable_autoscaling = false
}

module "cloudsql" {
  source       = "../../modules/cloudsql"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = "staging"
  region       = var.region
  vpc_id       = module.vpc.vpc_id
  db_tier      = "db-custom-2-7680"
}
