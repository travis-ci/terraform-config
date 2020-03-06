variable "project" {}

variable "nat_ip_count" {
  default = 1
}

variable "services_subnet_cidr_range" {
  default = "10.80.0.0/16"
}

variable "services_subnet_cidr_range_us_east4" {
  default = "10.81.0.0/16"
}

variable "services_subnet_cidr_range_us_east1" {
  default = "10.82.0.0/16"
}
