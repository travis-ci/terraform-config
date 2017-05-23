variable "env" {}
variable "index" {}
variable "instance_count" {}
variable "gce_project" {}
variable "gce_zone" {}
variable "gce_zone_suffix" {}

variable "gce_machine_type" {
  default = "g1-small"
}

variable "hashistack_server_image" {}

variable "cloud_init" {}
variable "gce_network" {}
variable "gce_subnetwork" {}
