variable "index" {}

variable "datacenter" {
  description = "The name of the vCenter datacenter that will run the created VMs"
}

variable "cluster" {
  description = "The vCenter compute cluster that should run the created VMs"
}

variable "datastore" {
  description = "The VMWare datastore that should hold the VM disks and configuration"
}

variable "internal_network_label" {
  description = "The label for the internal network for the MacStadium VPN"
}

variable "jobs_network_label" {
  description = "The label for the jobs network for the MacStadium VPN"
}

variable "jobs_network_subnet" {
  description = "The subnet for the jobs network where this cluster is running"
}

variable "mac_address" {
  description = "The MAC address assigned to the DHCP server VM on the jobs network"
}

variable "vanilla_image" {
  default = "travis-ci-centos7-internal-vanilla-1549473064"
}

variable "travisci_net_external_zone_id" {
  description = "The zone ID for the travisci.net DNS zone"
}

variable "ssh_user" {
  description = "your SSH username on our vanilla Linux images"
}
