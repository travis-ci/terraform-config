variable "env" {
  default = "staging"
}

variable "dns_domain" {
  default = "travisci.net"
}

variable "region" {
  default = "us-central1"
}

variable "gce_gcloud_zone" {}

resource "google_compute_address" "addr" {
  name   = "${var.env}-${var.index}-${var.name}"
  region = "${var.region}"
}

variable "image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1516675156-0b5be43"
}

variable "index" {
  default = 1
}

variable "name" {
  default = "docker-registry"
}

variable "project" {
  default = "eco-emissary-99515"
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

data "aws_route53_zone" "travisci_net" {
  name = "${var.dns_domain}."
}

variable "syslog_address" {}

variable "zone" {
  default = "us-central1-f"
}

resource "aws_route53_record" "a_rec" {
  zone_id = "${data.aws_route53_zone.travisci_net.zone_id}"
  name    = "${var.env}-${var.index}-${var.name}.gce-${var.region}.${var.dns_domain}"
  type    = "A"
  ttl     = 60

  records = ["${google_compute_address.addr.address}"]
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    here = "${path.module}"

    docker_registry_config = <<EOF
proxy:
  remoteurl: https://registry-1.docker.io
EOF

    docker_config = <<EOF
### docker.env
${file("${path.module}/docker.env")}

### in-line
export TRAVIS_DOCKER_HOSTNAME=${var.env}-${var.index}-${var.name}.gce-${var.region}.${var.dns_domain}
EOF

    syslog_address = "${var.syslog_address}"
  }
}

resource "google_compute_disk" "registry" {
  name = "${var.env}-${var.index}-${var.name}"
  type = "pd-ssd"
  zone = "${var.zone}"
  size = 500

  labels {
    environment = "${var.env}"
    name        = "${var.name}"
  }
}

resource "google_compute_instance" "instance" {
  name = "${var.env}-${var.index}-${var.name}"

  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["${var.name}", "${var.env}"]

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.image}"
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source = "${google_compute_disk.registry.self_link}"
  }

  network_interface {
    subnetwork = "public"

    access_config {
      nat_ip = "${google_compute_address.addr.address}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config.rendered}"
  }
}
