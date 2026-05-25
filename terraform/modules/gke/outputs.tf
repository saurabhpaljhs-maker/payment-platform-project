output "cluster_name"     { value = google_container_cluster.payments_cluster.name }
output "cluster_endpoint" { value = google_container_cluster.payments_cluster.endpoint }
output "cluster_ca_cert"  {
  value     = google_container_cluster.payments_cluster.master_auth[0].cluster_ca_certificate
  sensitive = true
}
