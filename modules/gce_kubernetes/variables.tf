variable "cluster_name" {}
variable "default_namespace" {}
variable "network" {}
variable "pool_name" {}
variable "project" {}
variable "region" {}
variable "subnetwork" {}

variable "min_master_version" {
  default = "1.13"
}

variable "initial_node_count" {
  default = "1"
}

variable "node_locations" {
  default = []
}

variable "node_pool_tags" {
  default = []
}

variable "min_node_count" {
  default = 1
}

variable "max_node_count" {
  default = 3
}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "enable_private_endpoint" {
  default = ""
}

variable "enable_private_nodes" {
  default = ""
}

variable "private_master_ipv4_cidr_block" {
  default = ""
}
