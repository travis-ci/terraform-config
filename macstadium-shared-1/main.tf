variable "index" { default = 1 }
variable "travisci_net_external_zone_id" { default = "Z2RI61YP4UWSIO" }
variable "macstadium_vanilla_image" { default = "travis-ci-ubuntu14.04-internal-vanilla-1481140635" }
variable "jupiter_brain_prod_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_staging_version" { default = "v0.2.0-58-gce0b45a" }
variable "ssh_user" {
  description = "your username on the wjb instances"
}

provider "aws" {}
provider "vsphere" {}

module "macstadium_infrastructure" {
  source = "../modules/macstadium_infrastructure"
  index = "${var.index}"
  vanilla_image = "${var.macstadium_vanilla_image}"
  datacenter = "TravisCI"
  cluster = "MacPro_Cluster"
  datastore = "EMC-VMAX-1"
  internal_network_label = "dvPortGroup-Internal"
  management_network_label = "dvPortGroup-Mgmt"
  jobs_network_label = "dvPortGroup-Jobs"
}

module "jupiter_brain_prod" {
  source = "../modules/jupiter_brain_bluegreen"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_prod_version}"
  config_path = "${path.module}/config/jupiter-brain-prod-env"
  env = "prod"
  index = "${var.index}"
  port_suffix = 1
}

module "jupiter_brain_staging" {
  source = "../modules/jupiter_brain_bluegreen"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_prod_version}"
  config_path = "${path.module}/config/jupiter-brain-staging-env"
  env = "staging"
  index = "${var.index}"
  port_suffix = 2
}

