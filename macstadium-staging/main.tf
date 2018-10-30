variable "index" {
  default = 3
}

variable "name_suffix" {
  default = "staging"
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "macstadium_vanilla_image" {
  default = "travis-ci-ubuntu14.04-internal-vanilla-1536648375"
}

variable "jobs_network_subnet" {
  default = "10.182.0.0/18"
}

variable "jobs_network_label" {
  default = "Jobs-1"
}

variable "jobs_network_mac_address" {
  default = "00:50:56:84:0b:a3"
}

variable "vsphere_janitor_version" {
  default = "8af7743"
}

variable "vsphere_monitor_version" {
  default = "0a459b3"
}

variable "collectd_vsphere_version" {
  default = "e1b57fe"
}

variable "ssh_user" {
  description = "your username on the wjb instances"
}

variable "threatstack_key" {}
variable "librato_email" {}
variable "librato_token" {}
variable "fw_ip" {}
variable "fw_snmp_community" {}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "vsphere_ip" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/macstadium-staging-terraform.tfstate"
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

module "macstadium_infrastructure_staging" {
  source                        = "../modules/macstadium_infrastructure_staging"
  index                         = "${var.index}"
  name_suffix                   = "${var.name_suffix}"
  vanilla_image                 = "${var.macstadium_vanilla_image}"
  datacenter                    = "pod-1"
  cluster                       = "MacPro_Staging_1"
  datastore                     = "DataCore1_1"
  internal_network_label        = "Internal"
  management_network_label      = "ESXi-MGMT"
  jobs_network_label            = "${var.jobs_network_label}"
  jobs_network_subnet           = "${var.jobs_network_subnet}"
  jobs_network_mac_address      = "${var.jobs_network_mac_address}"
  ssh_user                      = "${var.ssh_user}"
  threatstack_key               = "${var.threatstack_key}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vsphere_ip                    = "${var.vsphere_ip}"
  vm_ssh_key_path               = "${path.module}/config/travis-vm-ssh-key"
}

module "vsphere_janitor_staging_com" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-staging-com"
  env                     = "staging-com"
  index                   = "${var.index}"
}

resource "random_id" "collectd_vsphere_collectd_network_token" {
  byte_length = 32
}

module "collectd-vsphere-common" {
  source                                  = "../modules/collectd_vsphere"
  host_id                                 = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host                                = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user                                = "${var.ssh_user}"
  collectd_vsphere_version                = "${var.collectd_vsphere_version}"
  config_path                             = "${path.module}/config/collectd-vsphere-common"
  librato_email                           = "${var.librato_email}"
  librato_token                           = "${var.librato_token}"
  env                                     = "common"
  index                                   = "${var.index}"
  collectd_vsphere_collectd_network_user  = "collectd-vsphere-1"
  collectd_vsphere_collectd_network_token = "${random_id.collectd_vsphere_collectd_network_token.hex}"
  fw_ip                                   = "${var.fw_ip}"
  fw_snmp_community                       = "${var.fw_snmp_community}"
}

module "haproxy" {
  source   = "../modules/haproxy"
  host_id  = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user = "${var.ssh_user}"

  config = [
    {
      name               = "jupiter-brain-staging-org"
      frontend_port      = "8082"
      backend_port_blue  = "9082"
      backend_port_green = "10082"
    },
    {
      name               = "jupiter-brain-staging-com"
      frontend_port      = "8084"
      backend_port_blue  = "9084"
      backend_port_green = "10084"
    },
  ]
}

module "wjb-host-utilities" {
  source   = "../modules/macstadium_host_utilities"
  host_id  = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user = "${var.ssh_user}"
}
