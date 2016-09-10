resource "google_compute_instance" "nat-b" {
  name = "${var.env}-${var.index}-nat-b"
  machine_type = "g1-small"
  zone = "us-central1-b"
  tags = ["nat", "${var.env}"]
  can_ip_forward = true
  project = "${var.project}"

  disk {
    auto_delete = true
    image = "${var.nat_image}"
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
  next_hop_instance = "${google_compute_instance.nat-b.name}"
  next_hop_instance_zone = "us-central1-b"
  priority    = 800
  tags = ["worker", "testing"]

  project = "${var.project}"
}
