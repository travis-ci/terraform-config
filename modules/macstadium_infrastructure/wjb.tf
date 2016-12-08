resource "vsphere_virtual_machine" "wjb" {
  name = "wjb-${var.wjb_num}"
  folder = "${vsphere_folder.internal_vms.path}"
  vcpu = 4
  memory = 4096
  datacenter = "${var.datacenter}"
  cluster = "${var.cluster}"

  network_interface {
    label = "${var.internal_network_label}"
    ipv4_address = "${cidrhost("10.182.64.0/18", 30 + var.wjb_num)}"
    ipv4_gateway = "10.182.64.1"
    ipv4_prefix_length = "18"
  }

  network_interface {
    label = "${var.jobs_network_label}"
    ipv4_address = "${cidrhost("10.182.0.0/18", 30 + var.wjb_num)}"
    ipv4_prefix_length = "18"
  }

  network_interface {
    label = "${var.management_network_label}"
    ipv4_address = "${cidrhost("10.88.208.0/23", 496 + var.wjb_num)}"
    ipv4_prefix_length = "23"
  }

  disk {
    template = "${vsphere_folder.vanilla_vms.path}/${var.vanilla_image}"
    datastore = "${var.datastore}"
  }
}

output "wjb_ip" { value = "${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}" }
