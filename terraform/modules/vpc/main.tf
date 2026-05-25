# VPC Module — Payment Platform GCP
resource "google_compute_network" "payments_vpc" {
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id
  description             = "Private VPC for payment platform - ${var.environment}"
}

# GKE subnet with secondary ranges for pods and services
resource "google_compute_subnetwork" "gke_subnet" {
  name                     = "${var.project_name}-gke-subnet-${var.environment}"
  ip_cidr_range            = var.gke_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.payments_vpc.id
  project                  = var.project_id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private DB subnet — Cloud SQL has no public IP
resource "google_compute_subnetwork" "db_subnet" {
  name                     = "${var.project_name}-db-subnet-${var.environment}"
  ip_cidr_range            = var.db_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.payments_vpc.id
  project                  = var.project_id
  private_ip_google_access = true
}

# Cloud Router + NAT — private GKE nodes pull images from Artifact Registry
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router-${var.environment}"
  region  = var.region
  network = google_compute_network.payments_vpc.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-nat-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall — allow internal traffic only
resource "google_compute_firewall" "internal" {
  name    = "${var.project_name}-allow-internal-${var.environment}"
  network = google_compute_network.payments_vpc.name
  project = var.project_id
  allow { protocol = "tcp"; ports = ["0-65535"] }
  allow { protocol = "udp"; ports = ["0-65535"] }
  allow { protocol = "icmp" }
  source_ranges = [var.gke_subnet_cidr, var.db_subnet_cidr]
  description   = "Internal traffic between GKE nodes and DB subnet"
}
