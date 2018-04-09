variable "index" {
  default = 1
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "macstadium_vanilla_image" {
  default = "travis-ci-ubuntu14.04-internal-vanilla-1516305382"
}

variable "jobs_network_subnet" {
  default = "10.182.0.0/18"
}

variable "jobs_network_label" {
  default = "Jobs-1"
}

variable "vsphere_janitor_version" {
  default = "0a41b7f"
}

variable "vsphere_janitor_staging_version" {
  default = "0a41b7f"
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
    key            = "terraform-config/macstadium-pod-1-terraform.tfstate"
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

data "vsphere_datacenter" "pod" {
  name = "pod-1"
}

data "vsphere_datastore" "datacore1" {
  name          = "DataCore1_1"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_datastore" "datacore2" {
  name          = "DataCore1_2"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_datastore" "datacore3" {
  name          = "DataCore1_3"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_datastore" "datacore4" {
  name          = "DataCore1_4"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_resource_pool" "macpro_cluster" {
  name          = "MacPro_Pod_1/Resources"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_network" "internal" {
  name          = "Internal"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_network" "jobs" {
  name          = "Jobs-1"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

data "vsphere_network" "esxi" {
  name          = "ESXi-MGMT"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

module "macstadium_infrastructure" {
  source                        = "../modules/macstadium_infrastructure"
  index                         = "${var.index}"
  vanilla_image                 = "${var.macstadium_vanilla_image}"
  datacenter_id                 = "${data.vsphere_datacenter.pod.id}"
  resource_pool_id              = "${data.vsphere_resource_pool.macpro_cluster.id}"
  datastore_id                  = "${data.vsphere_datastore.datacore1.id}"
  internal_network_id           = "${data.vsphere_network.internal.id}"
  esxi_network_id               = "${data.vsphere_network.esxi.id}"
  jobs_network_id               = "${data.vsphere_network.jobs.id}"
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
  wjb_jobs_iface_mac            = "00:50:56:84:0b:a2"
}

module "vsphere_janitor_production_com" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-production-com"
  env         = "production-com"
  index       = "${var.index}"
}

module "vsphere_janitor_staging_com" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_staging_version}"
  config_path = "${path.module}/config/vsphere-janitor-staging-com"
  env         = "staging-com"
  index       = "${var.index}"
}

module "vsphere_janitor_custom_1" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-1"
  env         = "custom-1"
  index       = "${var.index}"
}

module "vsphere_janitor_custom_2" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-2"
  env         = "custom-2"
  index       = "${var.index}"
}

module "vsphere_janitor_custom_4" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-4"
  env         = "custom-4"
  index       = "${var.index}"
}

module "vsphere_janitor_custom_5" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-5"
  env         = "custom-5"
  index       = "${var.index}"
}

module "vsphere_janitor_custom_6" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-6"
  env         = "custom-6"
  index       = "${var.index}"
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
  source      = "../modules/vsphere_monitor"
  host_id     = "${module.macstadium_infrastructure.util_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.util_ip}"
  ssh_user    = "${var.ssh_user}"
  app_version = "${var.vsphere_monitor_version}"
  config_path = "${path.module}/config/vsphere-monitor"
  index       = "${var.index}"
}

resource "random_id" "collectd_vsphere_collectd_network_token" {
  byte_length = 32
}

module "collectd-vsphere-common" {
  source                                  = "../modules/collectd_vsphere"
  host_id                                 = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host                                = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user                                = "${var.ssh_user}"
  app_version                             = "${var.collectd_vsphere_version}"
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
      name               = "jupiter-brain-staging-org"
      frontend_port      = "8082"
      backend_port_blue  = "9082"
      backend_port_green = "10082"
    },
    {
      name               = "jupiter-brain-production-com"
      frontend_port      = "8083"
      backend_port_blue  = "9083"
      backend_port_green = "10083"
    },
    {
      name               = "jupiter-brain-staging-com"
      frontend_port      = "8084"
      backend_port_blue  = "9084"
      backend_port_green = "10084"
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
