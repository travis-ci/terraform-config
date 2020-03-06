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

resource "google_compute_subnetwork" "services-us-east1" {
  name                     = "services-us-east1"
  region                   = "us-east1"
  project                  = "${var.project}"
  ip_cidr_range            = "${var.services_subnet_cidr_range_us_east1}"
  network                  = "${google_compute_network.main.self_link}"
  enable_flow_logs         = "true"
  private_ip_google_access = "true"
}

resource "google_compute_subnetwork" "services-us-east4" {
  name                     = "services-us-east4"
  region                   = "us-east4"
  project                  = "${var.project}"
  ip_cidr_range            = "${var.services_subnet_cidr_range_us_east4}"
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

output "services_network_name_us_east1" {
  value = "${google_compute_subnetwork.services-us-east1.name}"
}

output "services_network_name_us_east4" {
  value = "${google_compute_subnetwork.services-us-east4.name}"
}
