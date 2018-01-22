resource "vsphere_virtual_machine" "dhcp_server" {
  name       = "dhcp-server-${var.index}"
  folder     = "${vsphere_folder.internal_vms.path}"
  vcpu       = 2
  memory     = 4096
  datacenter = "${var.datacenter}"
  cluster    = "${var.cluster}"
  domain     = "macstadium-us-se-1.travisci.net"

  network_interface {
    label = "${var.internal_network_label}"
  }

  network_interface {
    label              = "${var.jobs_network_label}"
    ipv4_address       = "${cidrhost(var.jobs_network_subnet, 10 + var.index)}"
    ipv4_prefix_length = "18"
  }

  disk {
    template  = "${vsphere_folder.vanilla_vms.path}/${var.vanilla_image}"
    datastore = "${var.datastore}"
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
