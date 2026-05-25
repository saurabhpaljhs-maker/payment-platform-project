variable "project_id"   { type = string }
variable "project_name" { type = string }
variable "environment"  { type = string }
variable "region"       { type = string }
variable "vpc_id"       { type = string }
variable "db_tier"      { type = string; default = "db-custom-2-7680" }
