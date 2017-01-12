variable "index" { default = 1 }
variable "travisci_net_external_zone_id" { default = "Z2RI61YP4UWSIO" }
variable "macstadium_vanilla_image" { default = "travis-ci-ubuntu14.04-internal-vanilla-1481140635" }
variable "jupiter_brain_prod_version" { default = "v0.2.0-58-gce0b45a" }
variable "jupiter_brain_staging_version" { default = "v0.2.0-58-gce0b45a" }
variable "travis_worker_staging_version" { default = "v2.5.0-46-g0e3fae5" }
variable "ssh_user" {
  description = "your username on the wjb instances"
}
variable "threatstack_key" {}

provider "aws" {}
provider "vsphere" {}

module "macstadium_infrastructure" {
  source = "../modules/macstadium_infrastructure"
  index = "${var.index}"
  vanilla_image = "${var.macstadium_vanilla_image}"
  datacenter = "TravisCI - Cluster_1"
  cluster = "MacPro_Cluster"
  datastore = "EMC-VMAX-1"
  internal_network_label = "dvPortGroup-Internal"
  management_network_label = "dvPortGroup-Mgmt"
  jobs_network_label = "dvPortGroup-Jobs"
  wjb_num = 1
  ssh_user = "${var.ssh_user}"
  threatstack_key = "${var.threatstack_key}"
}

module "jupiter_brain_prod_com" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_prod_version}"
  config_path = "${path.module}/config/jupiter-brain-prod-com-env"
  env = "com-prod"
  index = "${var.index}"
  port_suffix = 3
}

module "jupiter_brain_staging_com" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_prod_version}"
  config_path = "${path.module}/config/jupiter-brain-staging-com-env"
  env = "com-staging"
  index = "${var.index}"
  port_suffix = 4
}

module "jupiter_brain_custom_1" {
  source = "../modules/jupiter_brain_bluegreen"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.jupiter_brain_prod_version}"
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
  version = "${var.jupiter_brain_prod_version}"
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
  version = "${var.jupiter_brain_prod_version}"
  config_path = "${path.module}/config/jupiter-brain-custom-3-env"
  env = "custom-3"
  index = "${var.index}"
  port_suffix = 7
}

module "worker_com_staging_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-com-staging-1"
  vm_ssh_key_path = "${path.module}/config/travis-vm-ssh-key"
  env = "com-staging-1"
  index = "${var.index}"
}

module "worker_com_staging_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-com-staging-2"
  vm_ssh_key_path = "${path.module}/config/travis-vm-ssh-key"
  env = "com-staging-2"
  index = "${var.index}"
}

module "worker_custom_1" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-custom-1"
  vm_ssh_key_path = "${path.module}/config/travis-vm-ssh-key"
  env = "custom-1"
  index = "${var.index}"
}

module "worker_custom_2" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-custom-2"
  vm_ssh_key_path = "${path.module}/config/travis-vm-ssh-key"
  env = "custom-2"
  index = "${var.index}"
}

module "worker_custom_3" {
  source = "../modules/macstadium_go_worker"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.travis_worker_staging_version}"
  config_path = "${path.module}/config/travis-worker-custom-3"
  vm_ssh_key_path = "${path.module}/config/travis-vm-ssh-key"
  env = "custom-3"
  index = "${var.index}"
}

module "vsphere_janitor_prod_com" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-prod-com"
  env = "com-prod"
  index = "${var.index}"
}

module "vsphere_janitor_staging_com" {
  source = "../modules/vsphere_janitor"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"
  version = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-staging-com"
  env = "com-staging"
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

module "haproxy" {
  source = "../modules/haproxy"
  host_id = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user = "${var.ssh_user}"

  config {
    name = "jupiter-brain-staging-com"
    frontend_port = "8084"
    backend_port_blue = "9084"
    backend_port_green = "10084"
  }

  config {
    name = "jupiter-brain-prod-com"
    frontend_port = "8083"
    backend_port_blue = "9083"
    backend_port_green = "10083"
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
    frontend_port = "8086"
    backend_port_blue = "9086"
    backend_port_green = "10086"
  }
}
