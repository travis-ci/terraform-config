data "vsphere_datacenter" "dc" {
  name = "${var.datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "internal" {
  name          = "${var.internal_network_label}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "jobs" {
  name          = "${var.jobs_network_label}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

/*
data "vsphere_network" "management" {
  name          = "${var.management_network_label}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
*/

data "vsphere_virtual_machine" "vanilla_template" {
  name          = "Vanilla VMs/${var.vanilla_image}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
