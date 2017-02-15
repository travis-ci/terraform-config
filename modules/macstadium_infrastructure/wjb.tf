resource "vsphere_virtual_machine" "wjb" {
  name = "wjb-${var.index}"
  folder = "${vsphere_folder.internal_vms.path}"
  vcpu = 4
  memory = 4096
  datacenter = "${var.datacenter}"
  cluster = "${var.cluster}"
  domain = "macstadium-us-se-1.travisci.net"

  network_interface {
    label = "${var.internal_network_label}"
    ipv4_address = "${cidrhost("10.182.64.0/18", 30 + var.index)}"
    ipv4_gateway = "10.182.64.1"
    ipv4_prefix_length = "18"
  }

  network_interface {
    label = "${var.jobs_network_label}"
    ipv4_address = "${cidrhost("10.182.0.0/18", 30 + var.index)}"
    ipv4_prefix_length = "18"
  }

  network_interface {
    label = "${var.management_network_label}"
    ipv4_address = "${cidrhost("10.88.208.0/23", 496 + var.index)}"
    ipv4_prefix_length = "23"
  }

  disk {
    template = "${vsphere_folder.vanilla_vms.path}/${var.vanilla_image}"
    datastore = "${var.datastore}"
  }

  connection {
    host = "${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -s -v 'https://app.threatstack.com/agents/script?key=${var.threatstack_key}' | sudo bash"
    ]
  }
}

output "wjb_ip" { value = "${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}" }
output "wjb_uuid" { value = "${vsphere_virtual_machine.wjb.uuid}" }
