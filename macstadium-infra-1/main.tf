variable vsphere_user {}
variable vsphere_password {}
variable vsphere_server {}

variable index {
  default = "1"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/macstadium-infra-1.tfstate"
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

data "vsphere_virtual_machine" "internal_vanilla" {
  name          = "Vanilla VMs/travis-ci-ubuntu16.04-internal-vanilla-1525207848"
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
}

resource "vsphere_folder" "infrastructure_vms" {
  datacenter_id = "${data.vsphere_datacenter.pod.id}"
  path          = "Infrastructure VMs"
  type          = "vm"
}

resource "vsphere_virtual_machine" "dhcp_server" {
  name             = "dhcp-server-${var.index}"
  folder           = "${vsphere_folder.infrastructure_vms.path}"
  num_cpus         = 2
  memory           = 4096
  resource_pool_id = "${data.vsphere_resource_pool.macpro_cluster.id}"
  guest_id = "ubuntu64Guest"

  network_interface {
    network_id = "${data.vsphere_network.internal.id}"
  }

  network_interface {
    network_id = "${data.vsphere_network.jobs.id}"
  }

  disk {
    datastore_id = "${data.vsphere_datastore.datacore1.id}"
    label = "disk0"
    size = "15000"
  }

  cdrom {
    client_device = "true"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.internal_vanilla.id}"

    customize {
      linux_options {
        host_name = "dhcp-server-${var.index}"
        domain    = "macstadium.travisci.net"
      }
      network_interface {}
      network_interface {}
    }
  }

  connection {
    host  = "${vsphere_virtual_machine.dhcp_server.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }
}

resource "null_resource" "dhcp_server" {
  triggers {
    host_id = "${vsphere_virtual_machine.dhcp_server.uuid}"
  }

  connection {
    host  = "${vsphere_virtual_machine.dhcp_server.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }
}

#output "dhcp_server_ip" {
#  value = "${vsphere_virtual_machine.dhcp_server.network_interface.0.ipv4_address}"
#}


#output "dhcp_server_uuid" {
#  value = "${vsphere_virtual_machine.dhcp_server.uuid}"
#}

