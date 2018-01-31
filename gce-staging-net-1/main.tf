variable "env" {
  default = "staging"
}

variable "gce_bastion_image" {
  default = "eco-emissary-99515/bastion-1496867305"
}

variable "gce_nat_image" {
  default = "eco-emissary-99515/nat-1481594315"
}

variable "gce_gcloud_zone" {}
variable "github_users" {}

variable "index" {
  default = 1
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "deny_target_ip_ranges" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-stagingnet-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  credentials = "${file("config/gce-workers-staging-1.json")}"
  project     = "travis-staging-1"
  region      = "us-central1"
}

provider "aws" {}

module "gce_nat_1" {
  source = "../modules/gce_net"

  bastion_config                = "${file("config/bastion.env")}"
  bastion_image                 = "${var.gce_bastion_image}"
  deny_target_ip_ranges         = ["${split(",", var.deny_target_ip_ranges)}"]
  env                           = "${var.env}"
  gcloud_zone                   = "${var.gce_gcloud_zone}"
  github_users                  = "${var.github_users}"
  index                         = "${var.index}"
  nat_config                    = "${file("config/nat.env")}"
  nat_image                     = "${var.gce_nat_image}"
  nat_machine_type              = "g1-small"
  project                       = "travis-staging-1"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
}
