variable "env" {
  default = "production"
}

variable "index" {
  default = 1
}

variable "k8s_default_namespace" {
  default = "gce-production-1"
}

variable "project" {
  default = "eco-emissary-99515"
}

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

provider "kubernetes" {
  config_context = "${module.gke_cluster_2.context}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-net-1.tfstate"
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

module "gke_cluster_1" {
  source = "../modules/gce_kubernetes"
  
  cluster_name      = "gce-production-1"
  default_namespace = "${var.k8s_default_namespace}"
  network           = "${data.terraform_remote_state.vpc.gce_network_main}"
  pool_name         = "default"
  project           = "${var.project}"
  region            = "us-central1"
  subnetwork        = "${data.terraform_remote_state.vpc.gce_subnetwork_gke_cluster}"

  node_locations = ["us-central1-b", "us-central1-c"]
  node_pool_tags = ["gce-workers"]
  min_node_count = 4
  max_node_count = 50
  machine_type   = "c2-standard-4"
}

module "gce_worker_group_us_east1" {
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
  region                = "us-east1"
}

module "gke_cluster_2" {
  source = "../modules/gce_kubernetes"

  cluster_name      = "gce-production-1-ue1"
  default_namespace = "${var.k8s_default_namespace}"
  network           = "${data.terraform_remote_state.vpc.gce_network_main_us_east1}"
  pool_name         = "default"
  project           = "${var.project}"
  region            = "us-east1"
  subnetwork        = "${data.terraform_remote_state.vpc.gce_subnetwork_gke_cluster_us_east1}"

  node_locations = ["us-east1-c", "us-east1-d"]
  node_pool_tags = ["gce-workers"]
  min_node_count = 1
  max_node_count = 4
  machine_type   = "c2-standard-4"

  min_master_version = "1.14"
  initial_node_count = "2"
}

// Use these outputs to be able to easily set up a context in kubectl on the local machine.
output "cluster_host" {
  value = "${module.gke_cluster_2.host}"
}

output "cluster_ca_certificate" {
  value     = "${module.gke_cluster_1.cluster_ca_certificate}"
  sensitive = true
}

output "client_certificate" {
  value     = "${module.gke_cluster_1.client_certificate}"
  sensitive = true
}

output "client_key" {
  value     = "${module.gke_cluster_1.client_key}"
  sensitive = true
}

output "context" {
  value = "${module.gke_cluster_2.context}"
}

output "context_us_east1" {
  value = "${module.gke_cluster_2.context}"
}

output "workers_service_account_emails" {
  value = ["${module.gce_worker_group.workers_service_account_emails}"]
}

module "fair_use_ip_query_report" {
  source        = "../modules/fair_use_reporting"
  k8s_namespace = "${var.k8s_default_namespace}"
}

output "fair_use_ip_query_report_account_json" {
  value = "${module.fair_use_ip_query_report.fair_use_ip_query_report_account_json}"
}
