variable "env" {}

variable "images" {
  type = "list"
}

variable "image_project" {
  default = "eco-emissary-99515"
}

variable "index" {}
variable "machine_type" {}

variable "machine_type_short" {
  # d = default (2 cpus)
  # p = premium (4 cpus)
  default = "d"
}

variable "project" {}
variable "region" {}

variable "target_size" {
  default = "1"
}

variable "zones" {
  default = ["a", "b", "c", "f"]
}

resource "google_compute_instance_template" "warmer_pool_org" {
  count       = "${length(var.images)}"
  name_prefix = "${var.env}-${var.index}-warmer-pool-org-"

  machine_type = "${var.machine_type}"
  tags         = ["testing", "no-ip", "org"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = "https://www.googleapis.com/compute/v1/projects/${var.image_project}/global/images/${element(var.images, count.index)}"
  }

  network_interface {
    subnetwork = "jobs-org"
  }

  metadata {
    "block-project-ssh-keys" = "true"
  }
}

resource "google_compute_region_instance_group_manager" "warmer_pool_org" {
  count              = "${length(var.images)}"
  base_instance_name = "travis-job"
  instance_template  = "${element(google_compute_instance_template.warmer_pool_org.*.self_link, count.index)}"
  name               = "warmer-org-${var.machine_type_short}-${element(var.images, count.index)}"
  target_size        = "${var.target_size}"
  update_strategy    = "NONE"
  region             = "${var.region}"

  distribution_policy_zones = "${formatlist("${var.region}-%s", var.zones)}"
}
