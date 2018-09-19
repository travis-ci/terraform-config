variable "deny_target_ip_ranges" {}

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
  default = 3
}

variable "nat_conntracker_src_ignore" {
  type = "list"
}

variable "nat_conntracker_dst_ignore" {
  type = "list"
}

variable "project" {
  default = "travis-ci-prod-3"
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
    key            = "terraform-config/gce-production-net-3.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "aws" {}
provider "heroku" {}
