resource "google_compute_network" "main" {
  name = "main"
  project = "${var.project}"
}

output "gce_network" {
  value = "${google_compute_network.main.name}"
}

resource "google_compute_subnetwork" "public" {
  name = "public"
  ip_cidr_range = "10.10.1.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"

  project = "${var.project}"
}

output "gce_subnetwork_public" {
  value = "${google_compute_subnetwork.public.name}"
}

resource "google_compute_subnetwork" "workers" {
  name = "workers"
  ip_cidr_range = "10.10.2.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "build_org" {
  name = "buildorg"
  ip_cidr_range = "10.10.3.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "build_com" {
  name = "buildcom"
  ip_cidr_range = "10.10.4.0/24"
  network = "${google_compute_network.main.self_link}"
  region = "us-central1"

  project = "${var.project}"
}

resource "google_compute_firewall" "allow_ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.main.name}"
  source_ranges = ["0.0.0.0/0"]

  project = "${var.project}"

  allow {
    protocol = "tcp"
    ports = [22]
  }
}

resource "google_compute_firewall" "allow_internal" {
  name = "allow-internal"
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

resource "google_compute_firewall" "allow_nat" {
  name = "allow-nat"
  network = "${google_compute_network.main.name}"
  source_ranges = [
    "${google_compute_subnetwork.build_org.ip_cidr_range}",
    "${google_compute_subnetwork.build_com.ip_cidr_range}",
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
