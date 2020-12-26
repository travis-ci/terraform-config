variable "env" {
  default = "staging"
}

variable "gce_gcloud_zone" {}

variable "index" {
  default = 1
}

variable "project" {
  default = "travis-staging-1"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

data "aws_route53_zone" "travisci_net" {
  name = "travisci.net."
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

module "docker_registry_cache" {
  source                        = "../modules/gce_docker_registry_cache"
  index                         = "${var.index}"
  project                       = "${var.project}"
  region                        = "us-central1"
  syslog_address                = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${data.aws_route53_zone.travisci_net.zone_id}"
  gce_gcloud_zone               = "${var.gce_gcloud_zone}"
}
