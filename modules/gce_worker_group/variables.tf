variable "env" {}

variable "k8s_default_namespace" {}

variable "gcloud_cleanup_archive_retention_days" {
  default = 8
}

variable "github_users" {}
variable "heroku_org" {}
variable "index" {}
variable "project" {}
variable "region" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "travisci_net_external_zone_id" {}

variable "worker_config_com" {}
variable "worker_config_com_free" {}
variable "worker_config_org" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v6.2.0"
}

variable "worker_image" {
  default = "projects/ubuntu-os-cloud/global/images/family/ubuntu-1804-lts"
}

variable "worker_managed_instance_count_com" {
  default = 0
}

variable "worker_managed_instance_count_com_free" {
  default = 0
}

variable "worker_managed_instance_count_org" {
  default = 0
}

variable "worker_machine_type" {
  default = "g1-small"
}

variable "worker_network" {}
variable "worker_subnetwork" {}

variable "worker_zones" {
  default = ["a", "b", "c", "f"]
}
