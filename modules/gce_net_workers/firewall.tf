resource "google_compute_firewall" "allow_main_ssh" {
  name          = "allow-main-ssh"
  network       = "${google_compute_network.main.name}"
  source_ranges = ["${var.rigaer_strasse_8_ipv4}"]
  priority      = 1000
  project       = "${var.project}"

  allow {
    protocol = "tcp"
    ports    = [22]
  }

  lifecycle {
    ignore_changes = ["source_ranges"]
  }
}

resource "google_compute_firewall" "allow_gke_worker_to_jobs" {
  name    = "allow-gke-workers-to-jobs"
  network = "${google_compute_network.main.name}"

  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["gce-workers"]
  target_tags   = ["testing"]

  priority = 1000
  project  = "${var.project}"

  # 5986/wsman for Windows machines
  allow {
    protocol = "tcp"
    ports    = [22, 5986]
  }
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
  project = "${var.project}"

  source_ranges = [
    "${google_compute_subnetwork.public.ip_cidr_range}",
    "${google_compute_subnetwork.gke_cluster.ip_cidr_range}",
  ]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_jobs_nat" {
  name    = "allow-jobs-nat"
  network = "${google_compute_network.main.name}"
  project = "${var.project}"

  source_ranges = [
    "${google_compute_subnetwork.jobs_org.ip_cidr_range}",
    "${google_compute_subnetwork.jobs_com.ip_cidr_range}",
  ]

  target_tags = ["nat"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "deny_target_ip" {
  name    = "deny-target-ip"
  network = "${google_compute_network.main.name}"

  direction          = "EGRESS"
  destination_ranges = ["${var.deny_target_ip_ranges}"]

  project = "${var.project}"

  priority = "1"

  deny {
    protocol = "all"
  }
}
