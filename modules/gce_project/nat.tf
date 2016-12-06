resource "google_compute_address" "nat-b" {
  name = "nat-b"
  region = "us-central1"
  project = "${var.project}"
}

resource "aws_route53_record" "nat-b" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "nat-${var.env}.gce-us-central1-b.travisci.net"
  type = "A"
  ttl = 5
  records = [
    "${google_compute_address.nat-b.address}"
  ]
}

resource "google_compute_instance" "nat-b" {
  name = "${var.env}-${var.index}-nat-b"
  machine_type = "${var.nat_machine_type}"
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
      nat_ip = "${google_compute_address.nat-b.address}"
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
