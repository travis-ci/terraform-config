resource "google_compute_address" "services_nat" {
  count   = "${var.nat_ip_count}"
  name    = "services-nat-ip-${count.index}"
  project = "${var.project}"
}

resource "google_compute_router" "services_nat" {
  name    = "router"
  project = "${var.project}"
  network = "${google_compute_network.main.self_link}"

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "services_nat" {
  name    = "services-nat"
  project = "${var.project}"

  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.services_nat.*.self_link}"]
  router                             = "${google_compute_router.services_nat.name}"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = "${google_compute_subnetwork.services.self_link}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
