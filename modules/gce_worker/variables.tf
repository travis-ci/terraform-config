variable "config_com" {}
variable "config_com_free" {}
variable "config_org" {}
variable "env" {}
variable "github_users" {}
variable "index" {}
variable "managed_instance_count_com" {}
variable "managed_instance_count_com_free" {}
variable "managed_instance_count_org" {}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "project" {}
variable "region" {}

variable "regions_abbrev" {
  default = {
    "us-central1" = "uc1"
    "us-east1"    = "ue1"
  }
}

variable "subnetwork_workers" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "worker_docker_self_image" {}

variable "worker_image" {
  default = "projects/ubuntu-os-cloud/global/images/family/ubuntu-1804-lts"
}

variable "zones" {
  default = ["a", "b", "c", "f"]
}
