variable "account_json_com" {}
variable "account_json_org" {}
variable "config_com" {}
variable "config_org" {}
variable "env" {}
variable "github_users" {}
variable "index" {}
variable "instance_count_com" {}
variable "instance_count_org" {}

variable "machine_type" {
  default = "n1-standard-1"
}
variable "project" {}
variable "subnetwork_workers" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "worker_docker_self_image" {}
variable "worker_image" {}
variable "zone" {}
variable "zone_suffix" {}
