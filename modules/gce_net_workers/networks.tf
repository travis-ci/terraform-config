resource "google_compute_network" "main" {
  name                    = "main"
  project                 = "${var.project}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public" {
  name             = "public"
  ip_cidr_range    = "${var.public_subnet_cidr_range}"
  network          = "${google_compute_network.main.self_link}"
  region           = "${var.region}"
  project          = "${var.project}"
  enable_flow_logs = "true"
}

resource "google_compute_subnetwork" "jobs_org" {
  name             = "jobs-org"
  ip_cidr_range    = "${var.jobs_org_subnet_cidr_range}"
  network          = "${google_compute_network.main.self_link}"
  region           = "${var.region}"
  project          = "${var.project}"
  enable_flow_logs = "true"
}

resource "google_compute_subnetwork" "jobs_com" {
  name             = "jobs-com"
  ip_cidr_range    = "${var.jobs_com_subnet_cidr_range}"
  network          = "${google_compute_network.main.self_link}"
  region           = "${var.region}"
  project          = "${var.project}"
  enable_flow_logs = "true"
}

resource "google_compute_subnetwork" "gke_cluster" {
  name             = "gke-cluster"
  ip_cidr_range    = "${var.gke_cluster_subnet_cidr_range}"
  network          = "${google_compute_network.main.self_link}"
  region           = "${var.region}"
  project          = "${var.project}"
  enable_flow_logs = "true"
}
