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

resource "vsphere_folder" "custom_1_vms" {
  path       = "${var.custom_1_name} Build VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "custom_2_vms" {
  path       = "${var.custom_2_name} Build VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "custom_4_vms" {
  path       = "${var.custom_4_name} Build VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "custom_5_vms" {
  path       = "${var.custom_5_name} Build VMs"
  datacenter = "${var.datacenter}"
}

resource "vsphere_folder" "custom_6_vms" {
  path       = "${var.custom_6_name} Build VMs"
  datacenter = "${var.datacenter}"
}
