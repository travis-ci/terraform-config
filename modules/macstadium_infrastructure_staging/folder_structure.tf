resource "vsphere_folder" "internal_vms" {
  path       = "Internal VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "vanilla_vms" {
  path       = "Vanilla VMs"
  datacenter = "${var.datacenter}"
}
