variable "index" {
  default = 1
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "macstadium_vanilla_image" {
  default = "travis-ci-ubuntu18.04-internal-vanilla-1525123339"
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
    key            = "terraform-config/macstadium-pod-1-hopethisworks-terraform.tfstate"
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
  datacenter                    = "pod-1"
  cluster                       = "MacPro_Staging_1"
  datastore                     = "DataCore1_1"
  internal_network_label        = "Internal"
  management_network_label      = "ESXi-MGMT"
  jobs_network_label            = "${var.jobs_network_label}"
  jobs_network_subnet           = "${var.jobs_network_subnet}"
  ssh_user                      = "${var.ssh_user}"
  threatstack_key               = "${var.threatstack_key}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vsphere_ip                    = "${var.vsphere_ip}"
  vm_ssh_key_path               = "${path.module}/config/travis-vm-ssh-key"
}

module "vsphere_janitor_staging_com" {
  source      = "../modules/vsphere_janitor"
  host_id     = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host    = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user    = "${var.ssh_user}"
  version     = "${var.vsphere_janitor_version}"
  config_path = "${path.module}/config/vsphere-janitor-staging-com"
  env         = "staging-com"
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
  version     = "${var.vsphere_monitor_version}"
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
  version                                 = "${var.collectd_vsphere_version}"
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
      name               = "jupiter-brain-staging-org"
      frontend_port      = "8082"
      backend_port_blue  = "9082"
      backend_port_green = "10082"
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

resource "vsphere_virtual_machine" "image-builder" {
  name       = "image-builder"
  folder     = "Internal VMs"
  vcpu       = 2
  memory     = 4096
  datacenter = "pod-1"
  cluster    = "MacPro_Staging_1"
  domain     = "macstadium-us-se-1.travisci.net"

  network_interface {
    label = "Internal"
  }

  disk {
    template  = "Vanilla VMs/travis-ci-ubuntu18.04-internal-vanilla-1525123339"
    datastore = "DataCore1_1"
  }

  connection {
    host  = "${vsphere_virtual_machine.image-builder.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }
}

data "template_file" "image_builder_installer" {
  template = "${file("install-image-builder.sh")}"
}

data "template_file" "build_macos_script" {
  template = "${file("build-macos.sh")}"
}

data "template_file" "image_builder_env" {
  template = "${file("config/image-builder")}"
}

resource "null_resource" "image-builder-environment" {
  triggers {
    host_id                  = "${vsphere_virtual_machine.image-builder.uuid}"
    install_script_signature = "${sha256(data.template_file.image_builder_installer.rendered)}"
    run_script_signature     = "${sha256(data.template_file.build_macos_script.rendered)}"
    env_signature            = "${sha256(data.template_file.image_builder_env.rendered)}"
  }

  connection {
    host  = "${vsphere_virtual_machine.image-builder.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content     = "${data.template_file.image_builder_installer.rendered}"
    destination = "/tmp/install-image-builder.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-image-builder.sh",
      "sudo /tmp/install-image-builder.sh",
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.build_macos_script.rendered}"
    destination = "/tmp/build-macos.sh"
  }

  provisioner "file" {
    content     = "${data.template_file.image_builder_env.rendered}"
    destination = "/tmp/packer-env"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/build-macos.sh /home/packer/bin/build-macos",
      "sudo chown packer:packer /home/packer/bin/build-macos",
      "sudo chmod +x /home/packer/bin/build-macos",
      "sudo mv /tmp/packer-env /home/packer/.packer-env",
      "sudo chown packer:packer /home/packer/.packer-env",
    ]
  }
}

resource "aws_route53_record" "image-builder" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "image-builder.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.image-builder.network_interface.0.ipv4_address}"]
}
