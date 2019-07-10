variable "env" {
  default = "staging"
}

variable "gce_heroku_org" {}
variable "github_users" {}

variable "index" {
  default = 1
}

variable "job_board_url" {}
variable "latest_docker_image_worker" {}

variable "project" {
  default = "travis-staging-1"
}

variable "k8s_default_namespace" {
  default = "gce-staging-1"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

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
  project = "${var.project}"
  region  = "us-central1"
}

provider "aws" {}
provider "heroku" {}

provider "kubernetes" {
  # NOTE: For imports, config_context needs to be hardcoded and host/client/cluster needs to be commented out.

  #config_context = "gke_travis-staging-1_us-central1-a_gce-staging-1"

  host                   = "${module.gke_cluster_1.host}"
  client_certificate     = "${module.gke_cluster_1.client_certificate}"
  client_key             = "${module.gke_cluster_1.client_key}"
  cluster_ca_certificate = "${module.gke_cluster_1.cluster_ca_certificate}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-staging-net-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

module "aws_iam_user_s3_com" {
  source = "../modules/aws_iam_user_s3"

  iam_user_name  = "worker-gce-${var.env}-${var.index}-com"
  s3_bucket_name = "build-trace-staging.travis-ci.com"
}

module "aws_iam_user_s3_org" {
  source = "../modules/aws_iam_user_s3"

  iam_user_name  = "worker-gce-${var.env}-${var.index}-org"
  s3_bucket_name = "build-trace-staging.travis-ci.org"
}

module "gce_worker_group" {
  source = "../modules/gce_worker_group"

  env                           = "${var.env}"
  github_users                  = "${var.github_users}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "${var.index}"
  project                       = "${var.project}"
  region                        = "us-central1"
  syslog_address_com            = "${var.syslog_address_com}"
  syslog_address_org            = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  k8s_default_namespace         = "${var.k8s_default_namespace}"

  worker_docker_self_image = "${var.latest_docker_image_worker}"
  worker_subnetwork        = "${data.terraform_remote_state.vpc.gce_subnetwork_workers}"

  worker_zones = "${var.worker_zones}"

  worker_managed_instance_count_com      = "${length(var.worker_zones)}"
  worker_managed_instance_count_com_free = 0
  worker_managed_instance_count_org      = "${length(var.worker_zones)}"

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

module "gke_cluster_1" {
  source                = "../modules/gke_cluster"
  name                  = "gce-staging-1"
  gke_network           = "${data.terraform_remote_state.vpc.gce_network_main}"
  gke_subnetwork        = "${data.terraform_remote_state.vpc.gce_subnetwork_gke_cluster}"
  k8s_default_namespace = "${var.k8s_default_namespace}"

  # Legacy: should become us-central1 instead.
  region = "us-central1-a"
}

output "workers_service_account_emails" {
  value = ["${module.gce_worker_group.workers_service_account_emails}"]
}

output "latest_docker_image_worker" {
  value = "${var.latest_docker_image_worker}"
}

output "gcloud_cleanup_account_json" {
  value = "${module.gce_worker_group.gcloud_cleanup_account_json}"
}
