variable "project_id"      { type = string }
variable "project_name"    { type = string }
variable "environment"     { type = string }
variable "region"          { type = string; default = "us-central1" }
variable "gke_subnet_cidr" { type = string; default = "10.0.0.0/20" }
variable "db_subnet_cidr"  { type = string; default = "10.0.16.0/24" }
variable "pods_cidr"       { type = string; default = "10.1.0.0/16" }
variable "services_cidr"   { type = string; default = "10.2.0.0/20" }
