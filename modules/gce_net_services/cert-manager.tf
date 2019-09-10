resource "google_compute_firewall" "cert-manager-webhook-allow" {
  count   = "${var.cert_manager_enabled}"
  name    = "cert-manager-webhook-allow"
  network = "${google_compute_network.main.name}"
  project = "${var.project}"

  source_ranges = ["172.16.0.0/28"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_tags = "${var.cert_manager_source_tags}"
}
