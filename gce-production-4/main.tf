variable "env" {
  default = "production"
}

variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}

variable "gce_worker_image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1516675156-0b5be43"
}

variable "github_users" {}

variable "index" {
  default = 4
}

variable "job_board_url" {}

variable "project" {
  default = "travis-ci-prod-4"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "worker_instance_count_com" {}
variable "worker_instance_count_org" {}

variable "worker_instance_count_com_free" {
  default = "0"
}

variable "worker_zones" {
  default = ["a", "b", "f"]
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-4.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "us-central1"
}

provider "aws" {}
provider "heroku" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-net-4.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}
