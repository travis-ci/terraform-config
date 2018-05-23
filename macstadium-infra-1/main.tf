variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "travisci_net_external_zone_id" {}
variable "ssh_user" {}
variable "jobs_network_subnet" {
  default = "10.182.0.0/19"
}
variable "internal_network_subnet" {
  default = "10.182.64.0/24"
}

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
  guest_id         = "ubuntu64Guest"

  network_interface {
    network_id = "${data.vsphere_network.internal.id}"
  }

  network_interface {
    network_id = "${data.vsphere_network.jobs.id}"
        mac_address  = "00:50:56:84:b4:81"
  }

  disk {
    datastore_id = "${data.vsphere_datastore.datacore1.id}"
    label        = "disk0"
    size         = "15000"
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

      # by including these blank network iface blocks, we set the machine up to get an IP from DHCP :)
      network_interface = {
        ipv4_address = "10.182.64.50"
        ipv4_netmask = "18"
      }
      network_interface = {
        ipv4_address = "10.182.0.50"
        ipv4_netmask = "18"
      }
    }
  }

  vapp {
    properties {
      "user-data" = "asdf"
    }
  }

  connection {
    host  = "${vsphere_virtual_machine.dhcp_server.default_ip_address}"
    user  = "${var.ssh_user}"
    agent = true
  }
}

resource "null_resource" "dhcp_server_install" {
  triggers {
    host_id = "${vsphere_virtual_machine.dhcp_server.uuid}"
  }

  connection {
    host  = "${vsphere_virtual_machine.dhcp_server.default_ip_address}"
    user  = "${var.ssh_user}"
    agent = true
  }
}


resource "aws_route53_record" "dhcp_server" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "dhcp-server-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.dhcp_server.default_ip_address}"]
}

# tbh I don't know if we need to be outputting this right now
# output "dhcp_server_ip" {
#   value = "${vsphere_virtual_machine.dhcp_server.default_ip_address}"
# }


data "template_file" "dhcpd_install" {
  template = "${file("${path.module}/install-dhcpd.sh")}"
}

data "template_file" "dhcpd_defaults" {
  template = "${file("${path.module}/isc-dhcp-server-defaults")}"
}

resource "null_resource" "dhcp_server" {
  triggers {
    install_script_signature = "${sha256(data.template_file.dhcpd_install.rendered)}"
    dhcpd_defaults_signature = "${sha256(data.template_file.dhcpd_defaults.rendered)}"
    name                     = "dhcp_server-${var.index}"
    host_id                  = "${vsphere_virtual_machine.dhcp_server.uuid}"
  }

  connection {
    host  = "${vsphere_virtual_machine.dhcp_server.default_ip_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file"  {
    content = <<EOF
subnet ${cidrhost(var.jobs_network_subnet, 0)} netmask 255.255.224.0{
  option domain-name "macstadium-us-se-1.travisci.net";
  range ${cidrhost(var.jobs_network_subnet, 256)} ${cidrhost(var.jobs_network_subnet, -128)};
  option routers ${cidrhost(var.jobs_network_subnet, 1)};
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  default-lease-time 600;
  max-lease-time 600;
}

subnet ${cidrhost(var.internal_network_subnet, 0)} netmask 255.255.255.0{
  option domain-name "macstadium-us-se-1.travisci.net";
  range ${cidrhost(var.internal_network_subnet, 100)} ${cidrhost(var.internal_network_subnet, -50)};
  option routers ${cidrhost(var.internal_network_subnet, 1)};
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  default-lease-time 600;
  max-lease-time 600;
}
EOF
    destination = "/tmp/dhcpd.conf"
  }

  provisioner "file"  {
    content     = "${data.template_file.dhcpd_defaults.rendered}"
    destination = "/tmp/isc-dhcp-server-defaults"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.dhcpd_install.rendered}"]
  }
}
