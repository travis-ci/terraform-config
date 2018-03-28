variable "instance_count" {}
variable "index" {}
variable "env" {}
variable "worker_config" {}
variable "flavor_name" {}
variable "network" {}
variable "security_groups" {}
variable "worker_image" {}
variable "provider" {}
variable "key_name" {}
variable "availability_zone" {}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    here          = "${path.module}"
    worker_config = "${var.worker_config}"
    provider      = "${var.provider}"
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count           = "${var.instance_count}"
  name            = "${format("${var.env}-${var.index}-${var.provider}-worker-%02d", count.index + 1)}"
  image_name      = "${var.worker_image}"
  flavor_name     = "${var.flavor_name}"
  key_pair        = "${var.key_name}"
  security_groups = ["${var.security_groups}"]

  network {
    name = "${var.network}"
  }

  availability_zone = "${var.availability_zone}"
  user_data         = "${data.template_file.cloud_config.rendered}"
}
