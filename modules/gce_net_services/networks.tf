resource "google_compute_network" "main" {
  name                    = "main"
  project                 = "${var.project}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "services" {
  name                     = "services"
  project                  = "${var.project}"
  ip_cidr_range            = "${var.services_subnet_cidr_range}"
  network                  = "${google_compute_network.main.self_link}"
  enable_flow_logs         = "true"
  private_ip_google_access = "true"
}

output "main_network_name" {
  value = "${google_compute_network.main.name}"
}

output "services_network_name" {
  value = "${google_compute_subnetwork.services.name}"
}
