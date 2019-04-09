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
    key            = "terraform-config/macstadium-pod-2-cluster-terraform.tfstate"
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
  datacenter    = "pod-2"
  custom_1_name = "${var.custom_1_name}"
  custom_2_name = "${var.custom_2_name}"
  custom_4_name = "${var.custom_4_name}"
  custom_5_name = "${var.custom_5_name}"
  custom_6_name = "${var.custom_6_name}"
  custom_7_name = "${var.custom_7_name}"
}

module "kubernetes_cluster" {
  source                 = "../modules/macstadium_k8s_cluster"
  name_prefix            = "cluster-2"
  ip_base                = 90
  node_count             = 3
  datacenter             = "pod-2"
  cluster                = "MacPro_Pod_2"
  datastore              = "DataCore1_3"
  internal_network_label = "Internal"
  jobs_network_label     = "Jobs-2"
  jobs_network_subnet    = "10.182.128.0/18"

  mac_addresses = [
    "00:50:56:ab:0b:aa",
    "00:50:56:ab:0b:ab",
    "00:50:56:ab:0b:ac",
  ]

  // Kubernetes 1.14.0
  master_vanilla_image = "travis-ci-centos7-internal-kubernetes-1554237268"
  node_vanilla_image   = "travis-ci-centos7-internal-kubernetes-1554237268"

  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  ssh_user                      = "${var.ssh_user}"
}
