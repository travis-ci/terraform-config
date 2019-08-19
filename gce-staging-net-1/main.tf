variable "deny_target_ip_ranges" {
  default = []
}

variable "env" {
  default = "staging"
}

variable "latest_docker_image_gesund" {}
variable "latest_docker_image_nat_conntracker" {}
variable "latest_gce_bastion_image" {}

variable "gce_heroku_org" {}

variable "gce_nat_image" {
  # TODO: replace with vanilla ubuntu bionic image
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1520467760-573cd26"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "nat_conntracker_src_ignore" {
  type = "list"
}

variable "nat_conntracker_dst_ignore" {
  type = "list"
}

variable "project" {
  default = "travis-staging-1"
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
    key            = "terraform-config/gce-staging-net-1.tfstate"
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
  source = "../modules/gce_net_workers"

  bastion_config        = "${file("config/bastion.env")}"
  bastion_image         = "${var.latest_gce_bastion_image}"
  deny_target_ip_ranges = ["${var.deny_target_ip_ranges}"]
  env                   = "${var.env}"

  # TODO: replace with var.latest_docker_image_gesund
  gesund_self_image = "travisci/gesund:0.1.0"

  github_users                  = "${var.github_users}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "${var.index}"
  nat_config                    = "${file("config/nat.env")}"
  nat_conntracker_config        = "${file("nat-conntracker.env")}"
  nat_conntracker_dst_ignore    = ["${var.nat_conntracker_dst_ignore}"]
  nat_conntracker_src_ignore    = ["${var.nat_conntracker_src_ignore}"]
  nat_count_per_zone            = 2
  nat_image                     = "${var.gce_nat_image}"
  nat_machine_type              = "g1-small"
  project                       = "${var.project}"
  rigaer_strasse_8_ipv4         = "${var.rigaer_strasse_8_ipv4}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"

  nat_conntracker_redis_plan = "hobby-dev"
  nat_conntracker_self_image = "${var.latest_docker_image_nat_conntracker}"
}

output "gce_network_main" {
  value = "${module.gce_net.gce_network_main}"
}

output "gce_subnetwork_gke_cluster" {
  value = "${module.gce_net.gce_subnetwork_gke_cluster}"
}
