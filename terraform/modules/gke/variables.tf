variable "project_id"        { type = string }
variable "project_name"      { type = string }
variable "environment"       { type = string }
variable "region"            { type = string }
variable "vpc_name"          { type = string }
variable "gke_subnet_name"   { type = string }
variable "master_cidr"       { type = string; default = "172.16.0.0/28" }
variable "machine_type"      { type = string; default = "e2-standard-4" }
variable "node_count"        { type = number; default = 3 }
variable "enable_autoscaling"{ type = bool;   default = true }
variable "min_nodes"         { type = number; default = 3 }
variable "max_nodes"         { type = number; default = 10 }
