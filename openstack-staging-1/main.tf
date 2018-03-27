variable "os_username" {}
variable "os_tenant" {}
variable "os_password" {}
variable "os_auth_url" {}
variable "os_region" {}
variable "os_insecure" {}
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
  default = "openstack"
}

provider "openstack" {
  user_name   = "${var.os_username}"
  tenant_name = "${var.os_tenant}"
  password    = "${var.os_password}"
  auth_url    = "${var.os_auth_url}"
  region      = "${var.os_region}"
  insecure    = "${var.os_insecure}"
}

module "os_worker" {
  source            = "../modules/os_worker"
  instance_count    = 2
  index             = "${var.index}"
  env               = "staging"
  worker_image      = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  network           = "${var.network}"
  security_groups   = "${var.security_groups}"
  provider          = "${var.provider}"
  key_name          = "${var.key_name}"
  availability_zone = "${var.availability_zone}"

  worker_config = <<EOF
### worker.env
${file("${path.module}/worker.env")}
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_OPENSTACK_ENDPOINT="${var.os_auth_url}"
export TRAVIS_WORKER_OPENSTACK_TENANT_NAME="${var.os_tenant}"
export TRAVIS_WORKER_OPENSTACK_OS_USERNAME="${var.os_username}"
export TRAVIS_WORKER_OPENSTACK_OS_PASSWORD="${var.os_password}"
export TRAVIS_WORKER_OPENSTACK_OS_REGION="${var.os_region}"
export TRAVIS_WORKER_OPENSTACK_OS_ZONE="${var.availability_zone}"
EOF
}
