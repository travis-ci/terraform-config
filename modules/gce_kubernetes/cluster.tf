resource "google_container_cluster" "gke_cluster" {
  name               = "${var.cluster_name}"
  project            = "${var.project}"
  location           = "${var.region}"
  network            = "${var.network}"
  subnetwork         = "${var.subnetwork}"
  min_master_version = "${var.min_master_version}"
  node_locations     = "${var.node_locations}"

  initial_node_count       = 1
  remove_default_node_pool = true
  ip_allocation_policy     = {}
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  logging_service          = "logging.googleapis.com/kubernetes"

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }

    username = "${random_id.username.hex}"
    password = "${random_id.password.hex}"
  }

  private_cluster_config {
    enable_private_endpoint = "${var.enable_private_endpoint}"
    enable_private_nodes    = "${var.enable_private_nodes}"
  }
}

resource "google_container_node_pool" "node_pool" {
  name     = "${var.pool_name}"
  project  = "${var.project}"
  location = "${var.region}"
  cluster  = "${google_container_cluster.gke_cluster.name}"

  initial_node_count = 1

  node_config {
    machine_type = "${var.machine_type}"
    tags         = "${var.node_pool_tags}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_upgrade = false
    auto_repair  = true
  }

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}

output "host" {
  value = "${google_container_cluster.gke_cluster.endpoint}"
}

output "client_certificate" {
  value = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.client_certificate)}"
}

output "client_key" {
  value = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.client_key)}"
}

output "cluster_ca_certificate" {
  value = "${base64decode(google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)}"
}
