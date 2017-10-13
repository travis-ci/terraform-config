variable "env" {
  default = "staging"
}

variable "gce_bastion_image" {
  default = "eco-emissary-99515/bastion-1496867305"
}

variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}

variable "gce_worker_image" {
  default = "eco-emissary-99515/tfw-1499625597"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "job_board_url" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "latest_docker_image_worker" {}

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
  credentials = "${file("config/gce-workers-staging-1.json")}"
  project     = "travis-staging-1"
  region      = "us-central1"
}

provider "aws" {}

provider "heroku" {}

module "gce_project_1" {
  source                        = "../modules/gce_project"
  bastion_config                = "${file("${path.module}/config/bastion.env")}"
  bastion_image                 = "${var.gce_bastion_image}"
  env                           = "${var.env}"
  github_users                  = "${var.github_users}"
  gcloud_cleanup_account_json   = "${file("${path.module}/config/gce-cleanup-staging-1.json")}"
  gcloud_cleanup_job_board_url  = "${var.job_board_url}"
  gcloud_cleanup_loop_sleep     = "2m"
  gcloud_cleanup_scale          = "worker=1:Hobby"
  gcloud_zone                   = "${var.gce_gcloud_zone}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "${var.index}"
  project                       = "travis-staging-1"
  syslog_address_com            = "${var.syslog_address_com}"
  syslog_address_org            = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  worker_account_json_com       = "${file("${path.module}/config/gce-workers-staging-1.json")}"
  worker_account_json_org       = "${file("${path.module}/config/gce-workers-staging-1.json")}"
  worker_docker_self_image      = "${var.latest_docker_image_worker}"
  worker_image                  = "${var.gce_worker_image}"

  worker_instance_count_com = 4
  worker_instance_count_org = 4

  worker_config_com = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-com
export TRAVIS_WORKER_GCE_SITE=com
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_POOL_SIZE=35
export TRAVIS_WORKER_TRAVIS_SITE=com
EOF

  worker_config_org = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}

export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-org
export TRAVIS_WORKER_GCE_SITE=org
export TRAVIS_WORKER_POOL_SIZE=30
export TRAVIS_WORKER_TRAVIS_SITE=org
EOF
}
