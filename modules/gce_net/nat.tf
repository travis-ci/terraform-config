resource "google_compute_address" "nat" {
  count   = "${length(var.nat_zones) * var.nat_count_per_zone}"
  name    = "${element(var.nat_names, count.index)}"
  region  = "${var.region}"
  project = "${var.project}"
}

resource "aws_route53_record" "nat" {
  count   = "${length(var.nat_zones) * var.nat_count_per_zone}"
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "${element(var.nat_names, count.index)}.gce-${var.env}-${var.index}-${var.region}-${element(var.nat_zones, count.index / var.nat_count_per_zone)}.travisci.net"
  type    = "A"
  ttl     = 5

  records = ["${google_compute_address.nat.*.address[count.index]}"]
}

resource "aws_route53_record" "nat_regional" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat-${var.env}-${var.index}.gce-${var.region}.travisci.net"
  type    = "A"
  ttl     = 5

  records = ["${google_compute_address.nat.*.address}"]
}

resource "google_compute_router" "nat" {
  name    = "router"
  region  = "${google_compute_subnetwork.public.region}"
  network = "${google_compute_network.main.self_link}"
  project = "${var.project}"

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-1"
  router                             = "${google_compute_router.nat.name}"
  region                             = "${var.region}"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.nat.*.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = "${var.project}"

  subnetwork {
    name                    = "${google_compute_subnetwork.jobs_org.self_link}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = "${google_compute_subnetwork.jobs_com.self_link}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}
