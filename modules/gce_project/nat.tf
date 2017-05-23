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
