variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "ssh_user" {
  description = "your username on the Linux VM instances"
}

variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

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

module "kubernetes_cluster" {
  source                 = "../modules/macstadium_k8s_cluster"
  name_prefix            = "cluster-1"
  ip_base                = 80
  node_count             = 2
  datacenter             = "pod-1"
  cluster                = "MacPro_Pod_1"
  datastore              = "DataCore1_1"
  internal_network_label = "Internal"
  jobs_network_label     = "Jobs-1"
  jobs_network_subnet    = "10.182.0.0/18"

  mac_addresses = [
    "00:50:56:84:0b:aa",
    "00:50:56:84:0b:ab",
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
