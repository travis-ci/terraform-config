resource "vsphere_folder" "base_vms" {
  path       = "Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "datacore1_base_vms" {
  path       = "DATACORE 1 Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "datacore2_base_vms" {
  path       = "DATACORE 2 Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "datacore3_base_vms" {
  path       = "DATACORE 3 Base VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "datacore4_base_vms" {
  path       = "DATACORE 4 Base VMs"
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
