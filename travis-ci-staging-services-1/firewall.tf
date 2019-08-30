
resource "google_compute_firewall" "cert-manager-webhook-allow" {
  name    = "cert-manager-webhook-allow"
  network = "${module.networking.main_network_name}"
  project = "${module.project.project_id}"

  source_ranges = ["172.16.0.0/28"]
  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_tags = ["services"]
}
