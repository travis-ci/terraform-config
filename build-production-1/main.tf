variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "project" {
  default = "eco-emissary-99515"
}

variable "region" {
  default = "us-central1"
}

variable "syslog_address_com" {}

variable "zone" {
  default = "us-central1-f"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/build-production-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

module "remote_docker" {
  source = "../modules/gce_remote_docker"

  docker_ca_key_pem = "${file("config/docker-ca-key.pem")}"
  docker_ca_pem     = "${file("config/docker-ca.pem")}"
  env               = "${var.env}"
  github_users      = "${var.github_users}"
  index             = "${var.index}"
  name              = "build"
  region            = "${var.region}"
  repos             = ["travis-ci/travis-build"]
  syslog_address    = "${var.syslog_address_com}"
  zone              = "${var.zone}"
}
