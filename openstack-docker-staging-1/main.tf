variable "os_username" {}
variable "os_tenant" {}
variable "os_password" {}
variable "os_auth_url" {}
variable "os_region" {}
variable "key_name" {}

variable "availability_zone" {
  default = "nova"
}

variable "index" {
  default = 1
}

variable "image_name" {
  default = "Ubuntu 16.04 LE"
}

variable "flavor_name" {
  default = "m1.medium-travis-ci"
}

variable "network" {
  default = "public"
}

variable "security_groups" {
  default = "default"
}

variable "provider" {
  default = "docker"
}

variable "docker_storage_dm_basesize" {
  default = "19G"
}

provider "openstack" {
  user_name   = "${var.os_username}"
  tenant_name = "${var.os_tenant}"
  password    = "${var.os_password}"
  auth_url    = "${var.os_auth_url}"
  region      = "${var.os_region}"
}

module "os_worker" {
  source                     = "../modules/os_docker_worker"
  instance_count             = 1
  index                      = "${var.index}"
  env                        = "staging"
  worker_image               = "${var.image_name}"
  flavor_name                = "${var.flavor_name}"
  network                    = "${var.network}"
  security_groups            = "${var.security_groups}"
  provider                   = "${var.provider}"
  docker_storage_dm_basesize = "${var.docker_storage_dm_basesize}"
  key_name                   = "${var.key_name}"
  availability_zone          = "${var.availability_zone}"

  worker_config = <<EOF
### worker.env
${file("${path.module}/worker.env")}
export TRAVIS_WORKER_HARD_TIMEOUT=120m
EOF
}
