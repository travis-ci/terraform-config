resource "vsphere_folder" "base_vms" {
  path       = "Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "datacore_1_base_vms" {
  path       = "Pod ${var.index} Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "datacore_2_base_vms" {
  path       = "Pod ${var.index} Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "build_vms" {
  path       = "Build VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "internal_vms" {
  path       = "Internal VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "vanilla_vms" {
  path       = "Vanilla VMs"
  datacenter = "${var.datacenter}"
}
