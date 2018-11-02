variable "env" {
  default = "staging"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "machine_type" {
  default = "custom-1-2048"
}

variable "project" {
  default = "travis-staging-1"
}

variable "region" {
  default = "us-central1"
}

variable "syslog_address_com" {}

variable "zones" {
  default = ["a", "b", "c", "f"]
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/build-caching-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets         = "${path.module}/../assets"
    here           = "${path.module}"
    syslog_address = "${var.syslog_address_com}"

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "google_compute_instance_template" "build_cache" {
  name_prefix = "${var.env}-${var.index}-build-cache-"

  machine_type = "${var.machine_type}"
  tags         = ["build-cache", "${var.env}"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-1804-lts"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "public"

    access_config {}
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config.rendered}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "build_cache" {
  base_instance_name = "${var.env}-${var.index}-build-cache-gce-"
  instance_template  = "${google_compute_instance_template.build_cache.self_link}"
  name               = "build-cache"
  target_size        = 1
  region             = "${var.region}"

  distribution_policy_zones = "${formatlist("${var.region}-%s", var.zones)}"
}
