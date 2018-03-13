variable "env" {
  default = "staging"
}

variable "latest_docker_image_gesund" {}
variable "latest_docker_image_nat_conntracker" {}
variable "latest_gce_bastion_image" {}
variable "latest_gce_tfw_image" {}

variable "gce_heroku_org" {}
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
provider "heroku" {}

module "gce_net" {
  source = "../modules/gce_net"

  bastion_config                = "${file("config/bastion.env")}"
  bastion_image                 = "${var.latest_gce_bastion_image}"
  deny_target_ip_ranges         = ["${split(",", var.deny_target_ip_ranges)}"]
  env                           = "${var.env}"
  gesund_self_image             = "${var.latest_docker_image_gesund}"
  github_users                  = "${var.github_users}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "${var.index}"
  nat_config                    = "${file("config/nat.env")}"
  nat_conntracker_config        = "${file("nat-conntracker.env")}"
  nat_conntracker_redis_plan    = "hobby-dev"
  nat_conntracker_self_image    = "${var.latest_docker_image_nat_conntracker}"
  nat_image                     = "${var.latest_gce_tfw_image}"
  nat_machine_type              = "g1-small"
  project                       = "travis-staging-1"
  rigaer_strasse_8_ipv4         = "${var.rigaer_strasse_8_ipv4}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
}

output "gce_subnetwork_workers" {
  value = "${module.gce_net.gce_subnetwork_workers}"
}
