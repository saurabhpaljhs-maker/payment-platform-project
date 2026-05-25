output "vpc_id"          { value = google_compute_network.payments_vpc.id }
output "vpc_name"        { value = google_compute_network.payments_vpc.name }
output "gke_subnet_id"   { value = google_compute_subnetwork.gke_subnet.id }
output "gke_subnet_name" { value = google_compute_subnetwork.gke_subnet.name }
output "db_subnet_id"    { value = google_compute_subnetwork.db_subnet.id }
