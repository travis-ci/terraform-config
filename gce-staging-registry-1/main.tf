variable "env" {
  default = "staging"
}

variable "gce_gcloud_zone" {}

variable "index" {
  default = 1
}

variable "project" {
  default = "eco-emissary-99515"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-registry-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "us-central1"
}

data "terraform_remote_state" "registry_staging_1" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-registry-staging-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

module "docker_registry_cache" {
  source                        = "../modules/gce_docker_registry_cache"
  index                         = "${var.index}"
  project                       = "${var.project}"
  region                        = "us-central1"
  syslog_address                = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  gce_gcloud_zone               = "${var.gce_gcloud_zone}"
}
