variable "deny_target_ip_ranges" {
  default = []
}

variable "env" {
  default = "production"
}

variable "gce_bastion_image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/bastion-1519767738-74530dd"
}

variable "gce_heroku_org" {}

variable "gce_nat_image" {
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
  default = "eco-emissary-99515"
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
    key            = "terraform-config/gce-production-net-1.tfstate"
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
  bastion_image         = "${var.gce_bastion_image}"
  deny_target_ip_ranges = ["${var.deny_target_ip_ranges}"]
  env                   = "${var.env}"

  github_users                  = "${var.github_users}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "${var.index}"
  nat_config                    = "${file("config/nat.env")}"
  nat_conntracker_config        = "${file("nat-conntracker.env")}"
  nat_conntracker_dst_ignore    = ["${var.nat_conntracker_dst_ignore}"]
  nat_conntracker_src_ignore    = ["${var.nat_conntracker_src_ignore}"]
  nat_count_per_zone            = 2
  nat_image                     = "${var.gce_nat_image}"
  nat_machine_type              = "n1-standard-4"
  project                       = "${var.project}"
  rigaer_strasse_8_ipv4         = "${var.rigaer_strasse_8_ipv4}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
}

variable "nat_names_us_east1" {
  default = [
    "nat-b-1",
    "nat-c-1",
    "nat-d-1",
    "nat-b-2",
    "nat-c-2",
    "nat-d-2"
  ]
}

module "gce_net_us_east1" {
  source = "../modules/gce_net_workers"

  region = "us-east1"

  bastion_config        = "${file("config/bastion.env")}"
  bastion_image         = "${var.gce_bastion_image}"
  deny_target_ip_ranges = ["${var.deny_target_ip_ranges}"]
  env                   = "${var.env}"

  github_users                   = "${var.github_users}"
  heroku_org                     = "${var.gce_heroku_org}"
  index                          = "${var.index}"
  nat_config                     = "${file("config/nat.env")}"
  nat_conntracker_config         = "${file("nat-conntracker.env")}"
  nat_conntracker_dst_ignore     = ["${var.nat_conntracker_dst_ignore}"]
  nat_conntracker_src_ignore     = ["${var.nat_conntracker_src_ignore}"]
  nat_conntracker_name           = "nat-conn-gce-ue1"
  nat_count_per_zone             = 2
  nat_image                      = "${var.gce_nat_image}"
  nat_machine_type               = "n1-standard-4"
  project                        = "${var.project}"
  rigaer_strasse_8_ipv4          = "${var.rigaer_strasse_8_ipv4}"
  syslog_address                 = "${var.syslog_address_com}"
  travisci_net_external_zone_id  = "${var.travisci_net_external_zone_id}"
  google_compute_network_prefix  = "-us-east1"
  google_compute_firewall_prefix = "-us-east1"
  bastion_zones                  = ["b"]
  bastion_prefix                 = "-us-east1"
  nat_health_check_prefix        = "-us-east1"
  nat_zones                      = ["b", "c", "d"]
  nats_by_zone_prefix            = "us-east1-"
  nat_names                      = "${var.nat_names_us_east1}"

  nat_rolling_updater_config_prefix = "-us-east1"
}

data "google_compute_network" "main" {
  project = "${var.project}"
  name    = "main"
}

data "google_compute_network" "default" {
  project = "${var.project}"
  name    = "default"
}

resource "google_compute_firewall" "allow_docker_tls" {
  name    = "allow-docker-tls"
  network = "${data.google_compute_network.main.name}"

  allow {
    protocol = "tcp"
    ports    = ["2376"]
  }

  priority = 500

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dockerd"]
}

resource "google_compute_firewall" "allow_ssh_to_packer_templates_builds" {
  name        = "allow-ssh-to-packer-templates-builds"
  network     = "${data.google_compute_network.default.name}"
  description = "Allows SSH from testing VMs to packer-templates build VMs"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  priority = 1000

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["travis-ci-packer-templates"]
}

resource "google_compute_firewall" "allow_winrm_to_packer_templates_builds" {
  name    = "allow-winrm-to-packer-templates-builds"
  network = "${data.google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports    = ["5986"]
  }

  priority = 1000

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["travis-ci-packer-templates"]
}

output "gce_network_main" {
  value = "${module.gce_net.gce_network_main}"
}

output "gce_subnetwork_gke_cluster" {
  value = "${module.gce_net.gce_subnetwork_gke_cluster}"
}

output "gce_network_main_us_east1" {
  value = "${module.gce_net_us_east1.gce_network_main}"
}

output "gce_subnetwork_gke_cluster_us_east1" {
  value = "${module.gce_net_us_east1.gce_subnetwork_gke_cluster}"
}
