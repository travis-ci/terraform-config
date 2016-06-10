resource "google_compute_instance" "nat-b" {
  name = "${var.env}-${var.index}-nat-b"
  machine_type = "g1-small"
  zone = "us-central1-b"
  tags = ["nat", "${var.env}"]
  can_ip_forward = true
  project = "${var.gce_project}"

  disk {
    auto_delete = true
    image = "${var.gce_nat_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "public"
    access_config {
      # Ephemeral IP
    }
  }
}

resource "google_compute_route" "nat-b" {
  name        = "${var.env}-${var.index}-nat-b"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.main.name}"
  next_hop_ip = "${google_compute_instance.nat-b.network_interface.0.address}"
  priority    = 2000
  tags = ["worker"]

  project = "${var.gce_project}"
}
