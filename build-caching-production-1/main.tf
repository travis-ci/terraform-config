variable "project" {
  default = "eco-emissary-99515"
}

variable "region" {
  default = "us-central1"
}

variable "env" {
  default = "production"
}

variable "index" {
  default = 1
}

variable "github_users" {}
variable "librato_email" {}
variable "librato_token" {}
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

provider "google-beta" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "aws" {}

module "gce_squignix" {
  source = "../modules/gce_squignix"

  project = "${var.project}"
  region  = "${var.region}"
  env     = "${var.env}"
  index   = "${var.index}"

  github_users   = "${var.github_users}"
  librato_email  = "${var.librato_email}"
  librato_token  = "${var.librato_token}"
  syslog_address = "${var.syslog_address_com}"
}
