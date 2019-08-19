variable "project" {}

variable "nat_ip_count" {
  default = 1
}

variable "services_subnet_cidr_range" {
  default = "10.80.0.0/16"
}
