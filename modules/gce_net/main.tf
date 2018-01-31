variable "bastion_config" {}
variable "bastion_image" {}

variable "deny_target_ip_ranges" {
  type    = "list"
  default = []
}

variable "env" {}
variable "gcloud_zone" {}
variable "github_users" {}
variable "index" {}
variable "nat_config" {}
variable "nat_image" {}
variable "nat_machine_type" {}
variable "project" {}
variable "syslog_address" {}
variable "travisci_net_external_zone_id" {}

variable "public_subnet_cidr_range" {
  default = "10.10.0.0/22"
}

variable "workers_subnet_cidr_range" {
  default = "10.10.4.0/22"
}

variable "jobs_org_subnet_cidr_range" {
  default = "10.20.0.0/16"
}

variable "jobs_com_subnet_cidr_range" {
  default = "10.30.0.0/16"
}

variable "build_com_subnet_cidr_range" {
  default = "10.10.12.0/22"
}

variable "build_org_subnet_cidr_range" {
  default = "10.10.8.0/22"
}

resource "google_compute_network" "main" {
  name                    = "main"
  project                 = "${var.project}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public" {
  name          = "public"
  ip_cidr_range = "${var.public_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "workers" {
  name          = "workers"
  ip_cidr_range = "${var.workers_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "jobs_org" {
  name          = "jobs-org"
  ip_cidr_range = "${var.jobs_org_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

# TODO: remove this legacy subnetwork when no longer in use
resource "google_compute_subnetwork" "build_org" {
  name          = "buildorg"
  ip_cidr_range = "${var.build_org_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "jobs_com" {
  name          = "jobs-com"
  ip_cidr_range = "${var.jobs_com_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

# TODO: remove this legacy subnetwork when no longer in use
resource "google_compute_subnetwork" "build_com" {
  name          = "buildcom"
  ip_cidr_range = "${var.build_com_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_firewall" "allow_public_ssh" {
  name          = "allow-public-ssh"
  network       = "${google_compute_network.main.name}"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]

  project = "${var.project}"

  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_public_icmp" {
  name          = "allow-public-icmp"
  network       = "${google_compute_network.main.name}"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nat", "bastion"]

  project = "${var.project}"

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = "${google_compute_network.main.name}"

  source_ranges = [
    "${google_compute_subnetwork.public.ip_cidr_range}",
    "${google_compute_subnetwork.workers.ip_cidr_range}",
  ]

  project = "${var.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_firewall" "allow_jobs_nat" {
  name    = "allow-jobs-nat"
  network = "${google_compute_network.main.name}"

  source_ranges = [
    "${google_compute_subnetwork.jobs_org.ip_cidr_range}",
    "${google_compute_subnetwork.jobs_com.ip_cidr_range}",
  ]

  target_tags = ["nat"]

  project = "${var.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_firewall" "deny_target_ip" {
  name    = "deny-target-ip"
  network = "${google_compute_network.main.name}"

  direction          = "EGRESS"
  destination_ranges = ["${var.deny_target_ip_ranges}"]

  project = "${var.project}"

  # highest priority
  priority = "1000"

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }

  deny {
    protocol = "icmp"
  }
}

resource "google_compute_address" "nat-b" {
  name    = "nat-b"
  region  = "us-central1"
  project = "${var.project}"
}

resource "aws_route53_record" "nat-b" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat-${var.env}-${var.index}.gce-us-central1-b.travisci.net"
  type    = "A"
  ttl     = 5

  records = [
    "${google_compute_address.nat-b.address}",
  ]
}

data "template_file" "nat_cloud_config" {
  template = "${file("${path.module}/nat-cloud-config.yml.tpl")}"

  vars {
    nat_config       = "${var.nat_config}"
    cloud_init_bash  = "${file("${path.module}/nat-cloud-init.bash")}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    syslog_address   = "${var.syslog_address}"
  }
}

resource "google_compute_instance" "nat-b" {
  name         = "${var.env}-${var.index}-nat-b"
  machine_type = "${var.nat_machine_type}"
  zone         = "us-central1-b"
  tags         = ["nat", "${var.env}"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.nat_image}"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "public"

    access_config {
      nat_ip = "${google_compute_address.nat-b.address}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.nat_cloud_config.rendered}"
  }
}

resource "google_compute_address" "bastion-b" {
  name    = "bastion-b"
  region  = "us-central1"
  project = "${var.project}"
}

resource "aws_route53_record" "bastion-b" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "bastion-${var.env}-${var.index}.gce-us-central1-b.travisci.net"
  type    = "A"
  ttl     = 5

  records = [
    "${google_compute_address.bastion-b.address}",
  ]
}

data "template_file" "bastion_cloud_config" {
  template = "${file("${path.module}/bastion-cloud-config.yml.tpl")}"

  vars {
    bastion_config   = "${var.bastion_config}"
    cloud_init_bash  = "${file("${path.module}/bastion-cloud-init.bash")}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    syslog_address   = "${var.syslog_address}"
  }
}

resource "google_compute_instance" "bastion-b" {
  name         = "${var.env}-${var.index}-bastion-b"
  machine_type = "g1-small"
  zone         = "us-central1-b"
  tags         = ["bastion", "${var.env}"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.bastion_image}"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "public"

    access_config {
      nat_ip = "${google_compute_address.bastion-b.address}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.bastion_cloud_config.rendered}"
  }
}

output "gce_subnetwork_public" {
  value = "${google_compute_subnetwork.public.self_link}"
}
