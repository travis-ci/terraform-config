variable "bastion_config" {}
variable "bastion_image" {}

variable "bastion_zones" {
  default = ["b", "f"]
}

variable "deny_target_ip_ranges" {
  type    = "list"
  default = []
}

variable "env" {}

variable "gce_health_check_source_ranges" {
  default = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}

variable "gesund_self_image" {
  default = "travisci/gesund:0.1.0"
}

variable "github_users" {}
variable "heroku_org" {}
variable "index" {}
variable "nat_config" {}
variable "nat_conntracker_config" {}

variable "nat_conntracker_dst_ignore" {
  type    = "list"
  default = ["private"]
}

variable "nat_conntracker_src_ignore" {
  type    = "list"
  default = ["127.0.0.0/8", "10.10.0.0/16"]
}

variable "nat_conntracker_self_image" {
  default = "travisci/nat-conntracker:0.5.0"
}

variable "nat_conntracker_redis_plan" {
  default = "premium-0"
}

variable "nat_count_per_zone" {
  default = 1
}

variable "nat_image" {}

variable "nat_machine_type" {
  default = "custom-1-2048"
}

variable "nat_zones" {
  default = ["a", "b", "c", "f"]
}

variable "nat_names" {
  default = [
    "nat-a-1",
    "nat-b-1",
    "nat-c-1",
    "nat-f-1",
    "nat-a-2",
    "nat-b-2",
    "nat-c-2",
    "nat-f-2",
    "nat-a-3",
    "nat-b-3",
    "nat-c-3",
    "nat-f-3",
    "nat-a-4",
    "nat-b-4",
    "nat-c-4",
    "nat-f-4",
  ]
}

variable "project" {}

variable "region" {
  default = "us-central1"
}

variable "rigaer_strasse_8_ipv4" {}
variable "syslog_address" {}
variable "travisci_net_external_zone_id" {}

variable "public_subnet_cidr_range" {
  default = "10.10.0.0/22"
}

variable "workers_subnet_cidr_range" {
  default = "10.10.4.0/22"
}

variable "jobs_org_subnet_cidr_range" {
  default = "10.20.0.0/16"
}

variable "jobs_com_subnet_cidr_range" {
  default = "10.30.0.0/16"
}

variable "gke_cluster_subnet_cidr_range" {
  default = "10.40.0.0/16"
}

variable "build_com_subnet_cidr_range" {
  default = "10.10.12.0/22"
}

variable "build_org_subnet_cidr_range" {
  default = "10.10.8.0/22"
}

