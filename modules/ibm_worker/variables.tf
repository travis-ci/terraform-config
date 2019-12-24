
variable "basename" {
    default = "travisci"
}

variable "ibmcloud_zone" {
    default = "us-east"
}

variable "vpc_id" {}
variable "subnet_id" {}
variable "workers" {}
variable "workers_org" {
    default = 0
}
variable "image_id" {}
variable "profile_id" {}
variable "public_key_id" {}
variable "salt_master" {}
variable "travis_worker" {
    type = "map"
    default = {}
}
variable "travis_worker_org" {
    type = "map"
    default = {}
}
