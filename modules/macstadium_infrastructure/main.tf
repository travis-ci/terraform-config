variable "index" {}
variable "vanilla_image" {}
variable "datacenter_id" {}
variable "resource_pool_id" {}
variable "datastore_id" {}
variable "internal_network_id" {}
variable "esxi_network_id" {}
variable "jobs_network_id" {}
variable "jobs_network_subnet" {}
variable "threatstack_key" {}
variable "travisci_net_external_zone_id" {}
variable "vsphere_ip" {}
variable "ssh_user" {}
variable "vm_ssh_key_path" {}
variable "custom_1_name" {}
variable "custom_2_name" {}
variable "custom_4_name" {}
variable "custom_5_name" {}
variable "custom_6_name" {}
variable "wjb_jobs_iface_mac" {}
variable "dhcp_server_jobs_iface_mac" {}

data "vsphere_virtual_machine" "internal_vanilla" {
  name          = "Vanilla VMs/travis-ci-ubuntu14.04-internal-vanilla-1516305382"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "build_vms" {
  path          = "Build VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "internal_vms" {
  path          = "Internal VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "custom_1_vms" {
  path          = "${var.custom_1_name} Build VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "custom_2_vms" {
  path          = "${var.custom_2_name} Build VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "custom_4_vms" {
  path          = "${var.custom_4_name} Build VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "custom_5_vms" {
  path          = "${var.custom_5_name} Build VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_folder" "custom_6_vms" {
  path          = "${var.custom_6_name} Build VMs"
  type          = "vm"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_virtual_machine" "wjb" {
  name             = "wjb-${var.index}"
  num_cpus         = 4
  memory           = 4096
  folder           = "${vsphere_folder.internal_vms.path}"
  resource_pool_id = "${var.resource_pool_id}"
  datastore_id     = "${var.datastore_id}"
  guest_id         = "${data.vsphere_virtual_machine.internal_vanilla.guest_id}"

  disk {
    label        = "wjb-${var.index}.vmdk"
    size         = 10737
    datastore_id = "${var.datastore_id}"
  }

  network_interface {
    network_id = "${var.internal_network_id}"
  }

  network_interface {
    network_id     = "${var.jobs_network_id}"
    mac_address    = "${var.wjb_jobs_iface_mac}"
    use_static_mac = true
  }

  network_interface {
    network_id = "${var.esxi_network_id}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.internal_vanilla.id}"

    customize {
      linux_options {
        domain    = "macstadium-us-se-1.travisci.net"
        host_name = "wjb-${var.index}"
      }

      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", 30 + var.index)}"
        ipv4_netmask = "18"
      }

      network_interface {
        ipv4_address = "${cidrhost(var.jobs_network_subnet, 30 + var.index)}"
        ipv4_netmask = "18"
      }

      network_interface {
        ipv4_address = "${cidrhost("10.88.208.0/23", 496 + var.index)}"
        ipv4_netmask = "23"
      }

      ipv4_gateway = "10.182.64.1"
    }
  }

  connection {
    host  = "${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -s -v 'https://app.threatstack.com/agents/script?key=${var.threatstack_key}' | sudo bash",
    ]
  }
}

resource "null_resource" "worker" {
  triggers {
    host_id                = "${vsphere_virtual_machine.wjb.uuid}"
    ssh_key_file_signature = "${sha256(file(var.vm_ssh_key_path))}"
  }

  connection {
    host  = "${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source      = "${var.vm_ssh_key_path}"
    destination = "/tmp/travis-vm-ssh-key"
  }

  provisioner "remote-exec" {
    inline = [
      "if ! getent passwd travis-worker >/dev/null; then sudo useradd -r -s /usr/bin/nologin travis-worker; fi",
      "sudo mv /tmp/travis-vm-ssh-key /etc/travis-vm-ssh-key",
      "sudo chown travis-worker:travis-worker /etc/travis-vm-ssh-key",
      "sudo chmod 0600 /etc/travis-vm-ssh-key",
    ]
  }
}

output "wjb_ip" {
  value = "${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"
}

output "wjb_uuid" {
  value = "${vsphere_virtual_machine.wjb.uuid}"
}

resource "vsphere_virtual_machine" "util" {
  name             = "util-${var.index}"
  num_cpus         = 4
  memory           = 4096
  folder           = "${vsphere_folder.internal_vms.path}"
  resource_pool_id = "${var.resource_pool_id}"
  datastore_id     = "${var.datastore_id}"
  guest_id         = "${data.vsphere_virtual_machine.internal_vanilla.guest_id}"

  disk {
    label        = "util-${var.index}.vmdk"
    size         = 10737
    datastore_id = "${var.datastore_id}"
  }

  network_interface {
    network_id = "${var.internal_network_id}"
  }

  network_interface {
    network_id = "${var.esxi_network_id}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.internal_vanilla.id}"

    customize {
      linux_options {
        domain    = "macstadium-us-se-1.travisci.net"
        host_name = "util-${var.index}"
      }

      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", 40 + var.index)}"
        ipv4_netmask = "18"
      }

      network_interface {
        ipv4_address = "${cidrhost("10.88.208.0/23", 498 + var.index)}"
        ipv4_netmask = "23"
      }

      ipv4_gateway = "10.182.64.1"
    }
  }

  connection {
    host  = "${vsphere_virtual_machine.util.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -s -v 'https://app.threatstack.com/agents/script?key=${var.threatstack_key}' | sudo bash",
    ]
  }
}

output "util_ip" {
  value = "${vsphere_virtual_machine.util.network_interface.0.ipv4_address}"
}

output "util_uuid" {
  value = "${vsphere_virtual_machine.util.uuid}"
}

resource "vsphere_virtual_machine" "dhcp_server" {
  name             = "dhcp-server-${var.index}"
  folder           = "${vsphere_folder.internal_vms.path}"
  num_cpus         = 2
  memory           = 4096
  resource_pool_id = "${var.resource_pool_id}"
  datastore_id     = "${var.datastore_id}"
  guest_id         = "${data.vsphere_virtual_machine.internal_vanilla.guest_id}"

  network_interface {
    network_id = "${var.internal_network_id}"
  }

  network_interface {
    network_id     = "${var.jobs_network_id}"
    mac_address    = "${var.dhcp_server_jobs_iface_mac}"
    use_static_mac = true
  }

  disk {
  name             = "dhcp-server-${var.index}.vmdk"
  size = 10737
    datastore_id = "${var.datastore_id}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.internal_vanilla.id}"

    customize {
      linux_options {
        domain    = "macstadium-us-se-1.travisci.net"
        host_name = "dhcp-server-${var.index}"
      }

      network_interface = {}

      network_interface {
        ipv4_address = "${cidrhost(var.jobs_network_subnet, 10 + var.index)}"
        ipv4_netmask = "18"
      }
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

output "dhcp_server_ip" {
  value = "${vsphere_virtual_machine.dhcp_server.network_interface.0.ipv4_address}"
}

output "dhcp_server_uuid" {
  value = "${vsphere_virtual_machine.dhcp_server.uuid}"
}

resource "aws_route53_record" "vsphere" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "vsphere-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${var.vsphere_ip}"]
}

resource "aws_route53_record" "wjb" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "wjb-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"]
}

resource "aws_route53_record" "util" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "util-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.util.network_interface.0.ipv4_address}"]
}

resource "aws_route53_record" "dhcp_server" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "dhcp-server-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.dhcp_server.network_interface.0.ipv4_address}"]
}
