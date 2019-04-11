variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "ssh_user" {
  description = "your username on the Linux VM instances"
}

variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

variable "custom_1_name" {}
variable "custom_2_name" {}
variable "custom_4_name" {}
variable "custom_5_name" {}
variable "custom_6_name" {}
variable "custom_7_name" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/macstadium-pod-1-cluster-terraform.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

module "inventory" {
  source        = "../modules/macstadium_inventory"
  datacenter    = "pod-1"
  custom_1_name = "${var.custom_1_name}"
  custom_2_name = "${var.custom_2_name}"
  custom_4_name = "${var.custom_4_name}"
  custom_5_name = "${var.custom_5_name}"
  custom_6_name = "${var.custom_6_name}"
  custom_7_name = "${var.custom_7_name}"
}

module "kubernetes_cluster" {
  source                 = "../modules/macstadium_k8s_cluster"
  name_prefix            = "cluster-1"
  ip_base                = 80
  node_count             = 3
  datacenter             = "pod-1"
  cluster                = "MacPro_Pod_1"
  datastore              = "DataCore1_1"
  internal_network_label = "Internal"
  jobs_network_label     = "Jobs-1"
  jobs_network_subnet    = "10.182.0.0/18"

  mac_addresses = [
    "00:50:56:84:0b:aa",
    "00:50:56:84:0b:ab",
    "00:50:56:84:0b:ac",
  ]

  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  ssh_user                      = "${var.ssh_user}"
}

// Use these outputs to be able to easily set up a context in kubectl on the local machine.
output "cluster_host" {
  value = "${module.kubernetes_cluster.host}"
}

output "cluster_ca_certificate" {
  value     = "${module.kubernetes_cluster.cluster_ca_certificate}"
  sensitive = true
}

output "client_certificate" {
  value     = "${module.kubernetes_cluster.client_certificate}"
  sensitive = true
}

output "client_key" {
  value     = "${module.kubernetes_cluster.client_key}"
  sensitive = true
}

// This bucket and user will be used by imaged when deployed in the cluster.
// If the S3 user ever gets recreated, the travis-keychain will need to be updated
// so that imaged has the right credentials.

resource "aws_s3_bucket" "imaged_records" {
  acl    = "private"
  bucket = "imaged-records.travis-ci.com"
  region = "us-east-1"
}

module "aws_iam_user_s3_imaged" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "imaged-macstadium"
  s3_bucket_name = "${aws_s3_bucket.imaged_records.id}"
}

output "imaged_access_key" {
  value     = "${module.aws_iam_user_s3_imaged.id}"
  sensitive = true
}

output "imaged_secret_key" {
  value     = "${module.aws_iam_user_s3_imaged.secret}"
  sensitive = true
}

// These users are for the worker instances that will run on the cluster.
// The credentials are outputs so they can be copied into the keychain.
//
// If the users ever get recreated, those credentials need to get copied
// again so the Kubernetes secrets can be updated.
//
// This is not ideal, so I'd like to find a better way to manage this at
// point.

module "worker_com_s3_user" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-macstadium-prod-1-com"
  s3_bucket_name = "build-trace.travis-ci.com"
}

output "worker_com_access_key" {
  value     = "${module.worker_com_s3_user.id}"
  sensitive = true
}

output "worker_com_secret_key" {
  value     = "${module.worker_com_s3_user.secret}"
  sensitive = true
}

module "worker_org_s3_user" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-macstadium-prod-1-org"
  s3_bucket_name = "build-trace.travis-ci.org"
}

output "worker_org_access_key" {
  value     = "${module.worker_org_s3_user.id}"
  sensitive = true
}

output "worker_org_secret_key" {
  value     = "${module.worker_org_s3_user.secret}"
  sensitive = true
}
