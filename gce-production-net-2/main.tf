variable "deny_target_ip_ranges" {
  default = []
}

variable "env" {
  default = "production"
}

variable "index" {
  default = 2
}

variable "project" {
  default = "travis-ci-prod-2"
}

variable "region" {
  default = "us-central1"
}

variable "rigaer_strasse_8_ipv4" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-net-2.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google-beta" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "aws" {}
provider "heroku" {}

module "gce_net" {
  source = "../modules/gce_net"

  deny_target_ip_ranges         = ["${var.deny_target_ip_ranges}"]
  env                           = "${var.env}"
  index                         = "${var.index}"
  nat_count_per_zone            = 2
  project                       = "${var.project}"
  public_subnet_cidr_range      = "10.10.1.0/24"
  rigaer_strasse_8_ipv4         = "${var.rigaer_strasse_8_ipv4}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
}

output "gce_network_main" {
  value = "${module.gce_net.gce_network_main}"
}

output "gce_subnetwork_gke_cluster" {
  value = "${module.gce_net.gce_subnetwork_gke_cluster}"
}
