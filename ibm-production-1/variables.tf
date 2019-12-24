
variable "ibmcloud_api_key" {
    description = "Denotes the IBM Cloud API key to use"
}

variable "ibmcloud_generation" {
    description = "Denotes which generation of IBM Cloud to use (1 = classic; 2 = NextGen)"
    default     = "2"
}

variable "ibmcloud_region" {
    description = "Denotes which IBM Cloud region to connect to"
    default     = "us-south"
}

variable "ibmcloud_zone" {
    description = "Denotes which zone within the IBM Cloud region to create the VM in"
    default     = "us-south-3"
}

variable "ipv4_cidr_block" {
    description = "Denotes the CIDR block to create for the network subnet"
}

variable "image_id" {
    description = "Denotes which operating system image to boot"
    # Default is an Ubuntu 16.04 image
    default     = "cfdaf1a0-5350-4350-fcbc-97173b510843"
}

variable "profile_id" {
    description = "Denotes the VM profile to boot"
    default     = "bp2-8x32"
}

variable "public_key_id" {
    description = "Denotes the ID of the public key to use"
}

variable "workers" {
    description = "Workers count"
    default = "3"
}

variable "workers_org" {
    description = "Workers count on .org"
    default = "3"
}

variable "travis_worker" {
    type = "map"
    default = {}
}

variable "travis_worker_org" {
    type = "map"
    default = {}
}

variable "allowed_ips" {}
