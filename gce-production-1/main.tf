variable "env" {
  default = "production"
}

variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "job_board_url" {}

variable "project" {
  default = "eco-emissary-99515"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "worker_managed_instance_count_com" {}
variable "worker_managed_instance_count_org" {}
variable "worker_managed_instance_count_com_free" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-1.tfstate"
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
    key            = "terraform-config/gce-production-net-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

data "terraform_remote_state" "staging_1" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-staging-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

data "terraform_remote_state" "production_2" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-2.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

module "aws_iam_user_s3_com" {
  source = "../modules/aws_iam_user_s3"

  iam_user_name  = "worker-gce-${var.env}-${var.index}-com"
  s3_bucket_name = "build-trace.travis-ci.com"
}

module "aws_iam_user_s3_org" {
  source = "../modules/aws_iam_user_s3"

  iam_user_name  = "worker-gce-${var.env}-${var.index}-org"
  s3_bucket_name = "build-trace.travis-ci.org"
}

module "gce_worker_group" {
  source = "../modules/gce_worker_group"

  env                                       = "${var.env}"
  gcloud_cleanup_job_board_url              = "${var.job_board_url}"
  gcloud_cleanup_opencensus_sampling_rate   = "10"
  gcloud_cleanup_opencensus_tracing_enabled = "true"
  gcloud_zone                               = "${var.gce_gcloud_zone}"
  github_users                              = "${var.github_users}"
  heroku_org                                = "${var.gce_heroku_org}"
  index                                     = "${var.index}"
  project                                   = "${var.project}"
  region                                    = "us-central1"
  syslog_address_com                        = "${var.syslog_address_com}"
  syslog_address_org                        = "${var.syslog_address_org}"
  travisci_net_external_zone_id             = "${var.travisci_net_external_zone_id}"
  worker_subnetwork                         = "${data.terraform_remote_state.vpc.gce_subnetwork_workers}"

  worker_managed_instance_count_com      = "${var.worker_managed_instance_count_com}"
  worker_managed_instance_count_com_free = "${var.worker_managed_instance_count_com_free}"
  worker_managed_instance_count_org      = "${var.worker_managed_instance_count_org}"

  worker_config_com = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-com
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_QUEUE_NAME=builds.gce
export TRAVIS_WORKER_TRAVIS_SITE=com

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
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

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF

  worker_config_org = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-org
export TRAVIS_WORKER_TRAVIS_SITE=org

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

resource "google_project_iam_member" "staging_1_workers" {
  count   = "${length(data.terraform_remote_state.staging_1.workers_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.staging_1.workers_service_account_emails, count.index)}"
}

resource "google_project_iam_member" "staging_1_warmer" {
  count   = "${length(data.terraform_remote_state.staging_1.warmer_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.staging_1.warmer_service_account_emails, count.index)}"
}

resource "google_project_iam_member" "production_2_workers" {
  count   = "${length(data.terraform_remote_state.production_2.workers_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.production_2.workers_service_account_emails, count.index)}"
}

resource "google_project_iam_member" "production_2_warmer" {
  count   = "${length(data.terraform_remote_state.production_2.warmer_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.production_2.warmer_service_account_emails, count.index)}"
}
