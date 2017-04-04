variable "index" { default = 2 }
variable "travisci_net_external_zone_id" { default = "Z2RI61YP4UWSIO" }
variable "macstadium_vanilla_image" { default = "travis-ci-ubuntu14.04-internal-vanilla-1481140635" }
variable "jupiter_brain_production_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_staging_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_custom-1_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_custom-2_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_custom-3_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_custom-4_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_custom-5_version" { default = "v0.2.0-58-gce0b45a" }
variable "travis_worker_production_version" { default = "v2.6.2" }
variable "travis_worker_staging_version" { default = "v2.6.2" }
variable "travis_worker_custom-1_version" { default = "v2.6.2" }
variable "travis_worker_custom-2_version" { default = "v2.6.2" }
variable "travis_worker_custom-3_version" { default = "v2.6.2" }
variable "travis_worker_custom-4_version" { default = "v2.6.2" }
variable "travis_worker_custom-5_version" { default = "v2.6.2" }
variable "vsphere_janitor_version" { default = "0a41b7f" }
variable "vsphere_janitor_staging_version" { default = "0a41b7f" }
variable "vsphere_monitor_version" { default = "0a459b3" }
variable "collectd_vsphere_version" { default = "e1b57fe" }
variable "ssh_user" {
  description = "your username on the wjb instances"
}
variable "threatstack_key" {}
variable "librato_email" {}
variable "librato_token" {}
variable "collectd_vsphere_collectd_network_user" {}
variable "collectd_vsphere_collectd_network_token" {}
variable "fw_ip" {}
variable "fw_snmp_community" {}
variable "pfsense_1_ip" {}
variable "pfsense_1_snmp_community" {}
variable "pfsense_2_ip" {}
variable "pfsense_2_snmp_community" {}
variable "pfsense_2_1_ip" {}
variable "pfsense_2_1_snmp_community" {}
variable "pfsense_2_2_ip" {}
variable "pfsense_2_2_snmp_community" {}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "vsphere_ip" {}

terraform {
  backend "s3" {
    bucket = "travis-terraform-state"
    key = "terraform-config/macstadium-shared-2.tfstate"
    region = "us-east-1"
    encrypt = "true"
  }
}

provider "aws" {
  region = "us-east-1"
}
provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

module "macstadium_infrastructure" {
  source = "../modules/macstadium_infrastructure"
  index = "${var.index}"
  vanilla_image = "${var.macstadium_vanilla_image}"
  datacenter = "TravisCI - Cluster_2"
  cluster = "main_macpro"
  datastore = "EMC-VMAX-1"
  internal_network_label = "dvPortGroup-Internal"
  management_network_label = "dvPortGroup-Mgmt"
  jobs_network_label = "dvPortGroup-Jobs2"
  jobs_network_subnet = "10.182.128.0/18"
  ssh_user = "${var.ssh_user}"
  threatstack_key = "${var.threatstack_key}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vsphere_ip = "${var.vsphere_ip}"
  vm_ssh_key_path = "${path.module}/config/travis-vm-ssh-key"
}

module "jupiter_brain_production_org" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_production_version}"
  config_path = "${path.module}/config/jupiter-brain-production-org-env"
  env = "production-org"
  index = "${var.index}"
  port_suffix = 1
}

module "jupiter_brain_staging_org" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_production_version}"
  config_path = "${path.module}/config/jupiter-brain-staging-org-env"
  env = "staging-org"
  index = "${var.index}"
  port_suffix = 2
}

module "jupiter_brain_production_com" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_production_version}"
  config_path = "${path.module}/config/jupiter-brain-production-com-env"
  env = "production-com"
  index = "${var.index}"
  port_suffix = 3
}

module "jupiter_brain_production_com_xserve" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_production_version}"
  config_path = "${path.module}/config/jupiter-brain-production-com-xserve-env"
  env = "production-com-xserve"
  index = "${var.index}"
  port_suffix = 10
}

module "jupiter_brain_staging_com" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_production_version}"
  config_path = "${path.module}/config/jupiter-brain-staging-com-env"
  env = "staging-com"
  index = "${var.index}"
  port_suffix = 4
}

module "jupiter_brain_custom_1" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_custom-1_version}"
  config_path = "${path.module}/config/jupiter-brain-custom-1-env"
  env = "custom-1"
  index = "${var.index}"
  port_suffix = 5
}

module "jupiter_brain_custom_2" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_custom-2_version}"
  config_path = "${path.module}/config/jupiter-brain-custom-2-env"
  env = "custom-2"
  index = "${var.index}"
  port_suffix = 6
}

module "jupiter_brain_custom_3" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_custom-3_version}"
  config_path = "${path.module}/config/jupiter-brain-custom-3-env"
  env = "custom-3"
  index = "${var.index}"
  port_suffix = 7
}

module "jupiter_brain_custom_4" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_custom-4_version}"
  config_path = "${path.module}/config/jupiter-brain-custom-4-env"
  env = "custom-4"
  index = "${var.index}"
  port_suffix = 8
}

module "jupiter_brain_custom_5" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_custom-5_version}"
  config_path = "${path.module}/config/jupiter-brain-custom-5-env"
  env = "custom-5"
  index = "${var.index}"
  port_suffix = 9
}

module "worker_production_org_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_production_version}"
  config_path = "${path.module}/config/travis-worker-production-org-1"
  env = "production-org-1"
  index = "${var.index}"
}

module "worker_production_org_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_production_version}"
  config_path = "${path.module}/config/travis-worker-production-org-2"
  env = "production-org-2"
  index = "${var.index}"
}

module "worker_staging_org_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-staging-org-1"
  env = "staging-org-1"
  index = "${var.index}"
}

module "worker_staging_org_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-staging-org-2"
  env = "staging-org-2"
  index = "${var.index}"
}

module "worker_staging_com_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-staging-com-1"
  env = "staging-com-1"
  index = "${var.index}"
}

module "worker_com_staging_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-staging-com-2"
  env = "staging-com-2"
  index = "${var.index}"
}

module "worker_production_com_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_production_version}"
  config_path = "${path.module}/config/travis-worker-production-com-1"
  env = "production-com-1"
  index = "${var.index}"
}

module "worker_production_com_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_production_version}"
  config_path = "${path.module}/config/travis-worker-production-com-2"
  env = "production-com-2"
  index = "${var.index}"
}

module "worker_production_com_xserve_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_production_version}"
  config_path = "${path.module}/config/travis-worker-production-com-xserve-1"
  env = "production-com-xserve-1"
  index = "${var.index}"
}

module "worker_production_com_xserve_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_production_version}"
  config_path = "${path.module}/config/travis-worker-production-com-xserve-2"
  env = "production-com-xserve-2"
  index = "${var.index}"
}

module "worker_custom_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_custom-1_version}"
  config_path = "${path.module}/config/travis-worker-custom-1"
  env = "custom-1"
  index = "${var.index}"
}

module "worker_custom_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_custom-2_version}"
  config_path = "${path.module}/config/travis-worker-custom-2"
  env = "custom-2"
  index = "${var.index}"
}

module "worker_custom_3" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_custom-3_version}"
  config_path = "${path.module}/config/travis-worker-custom-3"
  env = "custom-3"
  index = "${var.index}"
}

module "worker_custom_4" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_custom-4_version}"
  config_path = "${path.module}/config/travis-worker-custom-4"
  env = "custom-4"
  index = "${var.index}"
}

module "worker_custom_5" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_custom-5_version}"
  config_path = "${path.module}/config/travis-worker-custom-5"
  env = "custom-5"
  index = "${var.index}"
}

module "vsphere_janitor_production_com" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-production-com"
  env = "production-com"
  index = "${var.index}"
}

module "vsphere_janitor_staging_com" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_staging_version}"
  config_path = "${path.module}/config/vsphere-janitor-staging-com"
  env = "staging-com"
  index = "${var.index}"
}

module "vsphere_janitor_custom_1" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-1"
  env = "custom-1"
  index = "${var.index}"
}

module "vsphere_janitor_custom_2" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-2"
  env = "custom-2"
  index = "${var.index}"
}

module "vsphere_janitor_custom_3" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-3"
  env = "custom-3"
  index = "${var.index}"
}

module "vsphere_janitor_custom_4" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-4"
  env = "custom-4"
  index = "${var.index}"
}

module "vsphere_janitor_custom_5" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-custom-5"
  env = "custom-5"
  index = "${var.index}"
}

module "vsphere_monitor" {
  source = "../modules/vsphere_monitor"
  host_id = "${module.macstadium_infrastructure.util_uuid}"
  ssh_host = "${module.macstadium_infrastructure.util_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_monitor_version}"
  config_path = "${path.module}/config/vsphere-monitor"
  index = "${var.index}"
}

module "collectd-vsphere-common" {
  source = "../modules/collectd_vsphere"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.collectd_vsphere_version}"
  config_path = "${path.module}/config/collectd-vsphere-common"
  librato_email = "${var.librato_email}"
  librato_token = "${var.librato_token}"
  env = "common"
  index = "${var.index}"
  collectd_vsphere_collectd_network_user = "${var.collectd_vsphere_collectd_network_user}"
  collectd_vsphere_collectd_network_token = "${var.collectd_vsphere_collectd_network_token}"
  fw_ip = "${var.fw_ip}"
  fw_snmp_community = "${var.fw_snmp_community}"
  pfsense_1_ip = "${var.pfsense_1_ip}"
  pfsense_1_snmp_community = "${var.pfsense_1_snmp_community}"
  pfsense_2_ip = "${var.pfsense_2_ip}"
  pfsense_2_snmp_community = "${var.pfsense_2_snmp_community}"
  pfsense_2_1_ip = "${var.pfsense_2_1_ip}"
  pfsense_2_1_snmp_community = "${var.pfsense_2_1_snmp_community}"
  pfsense_2_2_ip = "${var.pfsense_2_2_ip}"
  pfsense_2_2_snmp_community = "${var.pfsense_2_2_snmp_community}"
}

module "haproxy" {
  source = "../modules/haproxy"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"

  config {
    name = "jupiter-brain-production-org"
    frontend_port = "8081"
    backend_port_blue = "9081"
    backend_port_green = "10081"
  }

  config {
    name = "jupiter-brain-staging-org"
    frontend_port = "8082"
    backend_port_blue = "9082"
    backend_port_green = "10082"
  }

  config {
    name = "jupiter-brain-production-com"
    frontend_port = "8083"
    backend_port_blue = "9083"
    backend_port_green = "10083"
  }

  config {
    name = "jupiter-brain-staging-com"
    frontend_port = "8084"
    backend_port_blue = "9084"
    backend_port_green = "10084"
  }

  config {
    name = "jupiter-brain-custom-1"
    frontend_port = "8085"
    backend_port_blue = "9085"
    backend_port_green = "10085"
  }

  config {
    name = "jupiter-brain-custom-2"
    frontend_port = "8086"
    backend_port_blue = "9086"
    backend_port_green = "10086"
  }

  config {
    name = "jupiter-brain-custom-3"
    frontend_port = "8087"
    backend_port_blue = "9087"
    backend_port_green = "10087"
  }

  config {
    name = "jupiter-brain-custom-4"
    frontend_port = "8088"
    backend_port_blue = "9088"
    backend_port_green = "10088"
  }

  config {
    name = "jupiter-brain-custom-5"
    frontend_port = "8089"
    backend_port_blue = "9089"
    backend_port_green = "10089"
  }

  config {
    name = "jupiter-brain-production-com-xserve"
    frontend_port = "8090"
    backend_port_blue = "9090"
    backend_port_green = "10090"
  }
}
