variable "name_prefix" {
  default = "cluster"
}

variable "folder" {
  default = "Cluster VMs"
}

variable "ip_base" {
  description = "The starting value for the last component of VM IP addresses on the internal network."
}

variable "master_count" {
  default     = 1
  description = "The number of control plane nodes to create. Use 0 to create nodes to join an existing cluster."
}

variable "master_hostname" {
  default = ""
  description = "The host that clients will use to access the Kubernetes API server. Only needed if the cluster will be behind a load balancer."
}

variable "node_count" {
  default     = 1
  description = "The number of worker nodes to create."
}

variable "master_vanilla_image" {
  default     = "travis-ci-ubuntu16.04-internal-vanilla-1540931726"
  description = "The image to clone the master VM from. Needs to be at least Xenial to support Kubernetes."
}

variable "node_vanilla_image" {
  default     = "travis-ci-centos7-internal-kubernetes-1549480185"
  description = "The image to clone node VMs from. It should already have Kubernetes installed."
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

variable "jobs_network_label" {
  description = "The label for the jobs network for the MacStadium VPN"
}

variable "jobs_network_subnet" {
  description = "The subnet for the jobs network where this cluster is running"
}

variable "mac_addresses" {
  default     = []
  description = "The list of MAC addresses to assign the node VMs on the jobs network"
}

variable "travisci_net_external_zone_id" {
  description = "The zone ID for the travisci.net DNS zone"
}

variable "ssh_user" {
  description = "your SSH username on our vanilla Linux images"
}

variable "auth_org" {
  default     = "travis-ci"
  description = "The GitHub organization for users of this cluster"
}

variable "auth_admin_team" {
  default     = "Builders"
  description = "The GitHub team in the organization whose users will be made admins of the cluster"
}
