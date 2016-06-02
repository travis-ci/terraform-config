resource "google_compute_network" "dummy" {
  name = "dummy"
  project = "travis-staging"
}

resource "google_compute_network" "main" {
  name = "main"
  project = "travis-staging"
}

resource "google_compute_subnetwork" "public" {
  name = "public"
  ip_cidr_range = "10.10.1.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"
}

resource "google_compute_subnetwork" "workers_org" {
  name = "workersorg"
  ip_cidr_range = "10.10.2.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"
}

resource "google_compute_subnetwork" "workers_com" {
  name = "workerscom"
  ip_cidr_range = "10.10.3.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"
}

resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = "${google_compute_network.main.name}"

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.main.name}"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_firewall" "allow_internal" {
  name = "allow-internal"
  network = "${google_compute_network.main.name}"
  source_ranges = ["10.10.0.0/16"]

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

resource "google_compute_instance" "bastion-b" {
  name = "${var.env}-bastion-b"
  machine_type = "g1-small"
  zone = "us-central1-b"
  tags = ["bastion", "${var.env}"]

  disk {
    auto_delete = true
    image = "${var.gce_bastion_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "public"
    access_config {
      # Ephemeral IP
    }
  }
}

module "gce_worker_b" {
    source = "../modules/gce_worker"

    env = "${var.env}"
    instance_count = "1"
    gce_zone = "us-central1-b"
    gce_zone_suffix = "b"

    gce_machine_type = "g1-small"
    gce_worker_image = "${var.gce_worker_image}"
}

module "gce_worker_c" {
    source = "../modules/gce_worker"

    env = "${var.env}"
    instance_count = "1"
    gce_zone = "us-central1-c"
    gce_zone_suffix = "c"

    gce_machine_type = "g1-small"
    gce_worker_image = "${var.gce_worker_image}"
}
