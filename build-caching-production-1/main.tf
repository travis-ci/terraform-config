variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "librato_email" {}
variable "librato_token" {}

variable "project" {
  default = "eco-emissary-99515"
}

variable "region" {
  default = "us-central1"
}

variable "syslog_address_com" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/build-caching-production-1.tfstate"
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
  librato_email  = "${var.librato_email}"
  librato_token  = "${var.librato_token}"
  region         = "${var.region}"
  syslog_address = "${var.syslog_address_com}"
}
