# GKE Module — Payment Platform Cluster
# Private cluster — nodes have no public IPs
resource "google_container_cluster" "payments_cluster" {
  name     = "${var.project_name}-gke-${var.environment}"
  location = var.region
  project  = var.project_id

  # Use VPC from vpc module
  network    = var.vpc_name
  subnetwork = var.gke_subnet_name

  # Remove default node pool — we manage our own
  remove_default_node_pool = true
  initial_node_count       = 1

  # Private cluster — nodes get private IPs only
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity — no service account key files needed
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Network Policy (Calico)
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    http_load_balancing { disabled = false }
    horizontal_pod_autoscaling { disabled = false }
    network_policy_config { disabled = false }
  }

  maintenance_policy {
    daily_maintenance_window { start_time = "02:00" }
  }

  release_channel {
    channel = var.environment == "prod" ? "STABLE" : "REGULAR"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

# Node pool — payment services workload
resource "google_container_node_pool" "payment_nodes" {
  name       = "payment-node-pool"
  location   = var.region
  cluster    = google_container_cluster.payments_cluster.name
  project    = var.project_id
  node_count = var.node_count

  # Auto-scaling for prod — handles peak transaction load
  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count = var.min_nodes
      max_node_count = var.max_nodes
    }
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 50
    disk_type    = "pd-ssd"

    # Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      app         = "payment-platform"
    }

    tags = ["gke-node", var.environment]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
