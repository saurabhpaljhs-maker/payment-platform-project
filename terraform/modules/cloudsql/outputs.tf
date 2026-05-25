output "db_connection_name" { value = google_sql_database_instance.payments_db.connection_name }
output "db_private_ip"      { value = google_sql_database_instance.payments_db.private_ip_address }
output "db_instance_name"   { value = google_sql_database_instance.payments_db.name }
