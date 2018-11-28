variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 3
}

variable "project" {
  default = "travis-ci-prod-3"
}

variable "region" {
  default = "us-central1"
}

variable "syslog_address_com" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/build-caching-production-3.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "google-beta" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "aws" {}

module "gce_squignix" {
  source = "../modules/gce_squignix"

  env            = "${var.env}"
  github_users   = "${var.github_users}"
  index          = "${var.index}"
  region         = "${var.region}"
  syslog_address = "${var.syslog_address_com}"
}
