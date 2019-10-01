variable "env" {
  default = "staging"
}

variable "index" {
  default = 1
}

variable "k8s_default_namespace" {
  default = "default"
}

variable "project" {
  default = "travis-staging-1"
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

provider "kubernetes" {
  # NOTE: For imports, config_context needs to be hardcoded and host/client/cluster needs to be commented out.

  #config_context = "gke_travis-staging-1_us-central1-a_workers-1"

  host                   = "${module.workers_1.host}"
  client_certificate     = "${module.workers_1.client_certificate}"
  client_key             = "${module.workers_1.client_key}"
  cluster_ca_certificate = "${module.workers_1.cluster_ca_certificate}"
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

  aws_com_id            = "${module.aws_iam_user_s3_com.id}"
  aws_com_secret        = "${module.aws_iam_user_s3_com.secret}"
  aws_com_trace_bucket  = "${module.aws_iam_user_s3_com.bucket}"
  aws_org_id            = "${module.aws_iam_user_s3_org.id}"
  aws_org_secret        = "${module.aws_iam_user_s3_org.secret}"
  aws_org_trace_bucket  = "${module.aws_iam_user_s3_org.bucket}"
  env                   = "${var.env}"
  index                 = "${var.index}"
  k8s_default_namespace = "${var.k8s_default_namespace}"
  project               = "${var.project}"
  region                = "us-central1"
}

module "workers_1" {
  source = "../modules/gce_kubernetes"

  cluster_name      = "workers-1"
  default_namespace = "${var.k8s_default_namespace}"
  network           = "${data.terraform_remote_state.vpc.gce_network_main}"
  pool_name         = "default"
  project           = "${var.project}"
  region            = "us-central1"
  subnetwork        = "${data.terraform_remote_state.vpc.gce_subnetwork_gke_cluster}"

  node_locations     = ["us-central1-b", "us-central1-c"]
  node_pool_tags     = ["gce-workers"]
  max_node_count     = 10
  machine_type       = "c2-standard-4"
  min_master_version = "1.14"
}

// Use these outputs to be able to easily set up a context in kubectl on the local machine.
output "cluster_host" {
  value = "${module.workers_1.host}"
}

output "cluster_ca_certificate" {
  value     = "${module.workers_1.cluster_ca_certificate}"
  sensitive = true
}

output "client_certificate" {
  value     = "${module.workers_1.client_certificate}"
  sensitive = true
}

output "client_key" {
  value     = "${module.workers_1.client_key}"
  sensitive = true
}

output "context" {
  value = "${module.workers_1.context}"
}

output "workers_service_account_emails" {
  value = ["${module.gce_worker_group.workers_service_account_emails}"]
}
