variable "bastion_config" {}
variable "bastion_image" {}
variable "env" {}
variable "gcloud_cleanup_account_json" {}

variable "gcloud_cleanup_instance_max_age" {
  default = "3h"
}

variable "gcloud_cleanup_job_board_url" {}

variable "gcloud_cleanup_loop_sleep" {
  default = "1s"
}

variable "gcloud_cleanup_scale" {
  default = "worker=1:Standard-1X"
}

variable "gcloud_cleanup_version" {
  default = "master"
}

variable "gcloud_zone" {}
variable "github_users" {}
variable "heroku_org" {}
variable "index" {}
variable "project" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "travisci_net_external_zone_id" {}
variable "worker_account_json_com" {}
variable "worker_account_json_org" {}
variable "worker_config_com" {}
variable "worker_config_org" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v2.9.2"
}

variable "worker_image" {}
variable "worker_instance_count_com" {}
variable "worker_instance_count_org" {}

variable "public_subnet_cidr_range" {
  default = "10.10.0.0/22"
}

variable "workers_subnet_cidr_range" {
  default = "10.10.4.0/22"
}

variable "build_org_subnet_cidr_range" {
  default = "10.10.8.0/22"
}

variable "build_com_subnet_cidr_range" {
  default = "10.10.12.0/22"
}
