variable "name_prefix" {
  default = "cluster"
}

variable "folder" {
  default = "Cluster VMs"
}

variable "ip_base" {
  description = "The starting value for the last component of VM IP addresses on the internal network."
}

variable "node_count" {
  default = 1
}

variable "vanilla_image" {
  default = "travis-ci-ubuntu16.04-internal-vanilla-1540931726"
  description = "The image to clone VMs from. Needs to be at least Xenial to support Kubernetes."
}

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

variable "ssh_user" {
  description = "your SSH username on our vanilla Linux images"
}
