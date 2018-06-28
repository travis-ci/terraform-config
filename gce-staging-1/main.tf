variable "env" {
  default = "staging"
}

variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}
variable "latest_gce_tfw_image" {}
variable "github_users" {}

variable "gce_tfw_image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1523464380-560dabd"
}

variable "index" {
  default = 1
}

variable "job_board_url" {}
variable "latest_docker_image_worker" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "worker_zones" {
  default = ["a", "b", "c", "f"]
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "travis-staging-1"
  region  = "us-central1"
}

provider "aws" {}
provider "heroku" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-staging-net-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

module "gce_worker_group" {
  source = "../modules/gce_worker_group"

  env                           = "${var.env}"
  gcloud_cleanup_job_board_url  = "${var.job_board_url}"
  gcloud_cleanup_loop_sleep     = "2m"
  gcloud_cleanup_scale          = "worker=1:standard-1X"
  gcloud_zone                   = "${var.gce_gcloud_zone}"
  github_users                  = "${var.github_users}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "${var.index}"
  project                       = "travis-staging-1"
  region                        = "us-central1"
  syslog_address_com            = "${var.syslog_address_com}"
  syslog_address_org            = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  worker_docker_self_image      = "${var.latest_docker_image_worker}"
  worker_image                  = "${var.gce_tfw_image}"
  worker_subnetwork             = "${data.terraform_remote_state.vpc.gce_subnetwork_workers}"

  worker_zones = "${var.worker_zones}"

  worker_instance_count_com      = "${length(var.worker_zones)}"
  worker_instance_count_com_free = "1"
  worker_instance_count_org      = "${length(var.worker_zones)}"

  worker_config_com = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-com
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE=com
EOF

  worker_config_com_free = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce-free
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-com
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE=com
EOF

  worker_config_org = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-org
export TRAVIS_WORKER_TRAVIS_SITE=org
EOF
}

output "workers_service_account_email" {
  value = "${module.gce_worker_group.workers_service_account_email}"
}

output "workers_service_account_name" {
  value = "${module.gce_worker_group.workers_service_account_name}"
}
