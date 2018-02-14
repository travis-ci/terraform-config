variable "env" {
  default = "staging"
}

variable "latest_gce_bastion_image" {}
variable "latest_gce_nat_image" {}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "region" {
  default = "us-central1"
}

variable "rigaer_strasse_8_ipv4" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "deny_target_ip_ranges" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-staging-net-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  credentials = "${file("config/gce-workers-staging-1.json")}"
  project     = "travis-staging-1"
  region      = "${var.region}"
}

provider "aws" {}

module "gce_net" {
  source = "../modules/gce_net"

  bastion_config                = "${file("config/bastion.env")}"
  bastion_image                 = "${var.latest_gce_bastion_image}"
  deny_target_ip_ranges         = ["${split(",", var.deny_target_ip_ranges)}"]
  env                           = "${var.env}"
  github_users                  = "${var.github_users}"
  index                         = "${var.index}"
  nat_config                    = "${file("config/nat.env")}"
  nat_image                     = "${var.latest_gce_nat_image}"
  nat_machine_type              = "g1-small"
  project                       = "travis-staging-1"
  rigaer_strasse_8_ipv4         = "${var.rigaer_strasse_8_ipv4}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
}

resource "aws_route53_record" "nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat-${var.env}-${var.index}.gce-${var.region}.travisci.net"
  type    = "A"
  ttl     = 5

  records = ["${module.gce_net.nat_addresses}"]
}

output "gce_subnetwork_workers" {
  value = "${module.gce_net.gce_subnetwork_workers}"
}
