variable "index" {
  default = 2
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "macstadium_vanilla_image" {
  default = "travis-ci-ubuntu14.04-internal-vanilla-1516305382"
}

variable "jobs_network_subnet" {
  default = "10.182.128.0/18"
}

variable "jobs_network_label" {
  default = "Jobs-2"
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

variable "custom_1_name" {}
variable "custom_2_name" {}
variable "custom_4_name" {}
variable "custom_5_name" {}
variable "custom_6_name" {}
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
    key            = "terraform-config/macstadium-pod-2-terraform.tfstate"
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

module "macstadium_infrastructure" {
  source                        = "../modules/macstadium_infrastructure"
  index                         = "${var.index}"
  vanilla_image                 = "${var.macstadium_vanilla_image}"
  datacenter                    = "pod-2"
  cluster                       = "MacPro_Pod_2"
  datastore                     = "DataCore1_3"
  internal_network_label        = "Internal"
  management_network_label      = "ESXi-MGMT"
  jobs_network_label            = "${var.jobs_network_label}"
  jobs_network_subnet           = "${var.jobs_network_subnet}"
  ssh_user                      = "${var.ssh_user}"
  threatstack_key               = "${var.threatstack_key}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vsphere_ip                    = "${var.vsphere_ip}"
  vm_ssh_key_path               = "${path.module}/config/travis-vm-ssh-key"
  custom_1_name                 = "${var.custom_1_name}"
  custom_2_name                 = "${var.custom_2_name}"
  custom_4_name                 = "${var.custom_4_name}"
  custom_5_name                 = "${var.custom_5_name}"
  custom_6_name                 = "${var.custom_6_name}"
}

module "vsphere_janitor_production_com" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-production-com"
  env                     = "production-com"
  index                   = "${var.index}"
}

module "vsphere_janitor_custom_1" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-custom-1"
  env                     = "custom-1"
  index                   = "${var.index}"
}

module "vsphere_janitor_custom_2" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-custom-2"
  env                     = "custom-2"
  index                   = "${var.index}"
}

module "vsphere_janitor_custom_4" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-custom-4"
  env                     = "custom-4"
  index                   = "${var.index}"
}

module "vsphere_janitor_custom_5" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-custom-5"
  env                     = "custom-5"
  index                   = "${var.index}"
}

module "vsphere_janitor_custom_6" {
  source                  = "../modules/vsphere_janitor"
  host_id                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_janitor_version = "${var.vsphere_janitor_version}"
  config_path             = "${path.module}/config/vsphere-janitor-custom-6"
  env                     = "custom-6"
  index                   = "${var.index}"
}

module "dhcp_server" {
  source              = "../modules/macstadium_dhcp_server"
  host_id             = "${module.macstadium_infrastructure.dhcp_server_uuid}"
  index               = "${var.index}"
  jobs_network_subnet = "${var.jobs_network_subnet}"
  ssh_host            = "${module.macstadium_infrastructure.dhcp_server_ip}"
  ssh_user            = "${var.ssh_user}"
}

module "vsphere_monitor" {
  source                  = "../modules/vsphere_monitor"
  host_id                 = "${module.macstadium_infrastructure.util_uuid}"
  ssh_host                = "${module.macstadium_infrastructure.util_ip}"
  ssh_user                = "${var.ssh_user}"
  vsphere_monitor_version = "${var.vsphere_monitor_version}"
  config_path             = "${path.module}/config/vsphere-monitor"
  index                   = "${var.index}"
}

resource "random_id" "collectd_vsphere_collectd_network_token" {
  byte_length = 32
}

module "collectd-vsphere-common" {
  source                                  = "../modules/collectd_vsphere"
  host_id                                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                                = "${var.ssh_user}"
  collectd_vsphere_version                = "${var.collectd_vsphere_version}"
  config_path                             = "${path.module}/config/collectd-vsphere-common"
  librato_email                           = "${var.librato_email}"
  librato_token                           = "${var.librato_token}"
  env                                     = "common"
  index                                   = "${var.index}"
  collectd_vsphere_collectd_network_user  = "collectd-vsphere-2"
  collectd_vsphere_collectd_network_token = "${random_id.collectd_vsphere_collectd_network_token.hex}"
  fw_ip                                   = "${var.fw_ip}"
  fw_snmp_community                       = "${var.fw_snmp_community}"
}

module "haproxy" {
  source   = "../modules/haproxy"
  host_id  = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"

  config = [
    {
      name               = "jupiter-brain-production-org"
      frontend_port      = "8081"
      backend_port_blue  = "9081"
      backend_port_green = "10081"
    },
    {
      name               = "jupiter-brain-production-com"
      frontend_port      = "8083"
      backend_port_blue  = "9083"
      backend_port_green = "10083"
    },
    {
      name               = "jupiter-brain-custom-1"
      frontend_port      = "8085"
      backend_port_blue  = "9085"
      backend_port_green = "10085"
    },
    {
      name               = "jupiter-brain-custom-2"
      frontend_port      = "8086"
      backend_port_blue  = "9086"
      backend_port_green = "10086"
    },
    {
      name               = "jupiter-brain-custom-4"
      frontend_port      = "8088"
      backend_port_blue  = "9088"
      backend_port_green = "10088"
    },
    {
      name               = "jupiter-brain-custom-5"
      frontend_port      = "8089"
      backend_port_blue  = "9089"
      backend_port_green = "10089"
    },
    {
      name               = "jupiter-brain-custom-6"
      frontend_port      = "8091"
      backend_port_blue  = "9091"
      backend_port_green = "10091"
    },
  ]
}

module "wjb-host-utilities" {
  source   = "../modules/macstadium_host_utilities"
  host_id  = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
}

module "util-host-utilities" {
  source   = "../modules/macstadium_host_utilities"
  host_id  = "${module.macstadium_infrastructure.util_uuid}"
  ssh_host = "${module.macstadium_infrastructure.util_ip}"
  ssh_user = "${var.ssh_user}"
}
