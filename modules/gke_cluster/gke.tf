variable "name" {
  default = "cluster"
}

variable "zone" {
  default = "us-central1-a"
}

variable "gke_network" {
  default = "default"
}

variable "gke_subnetwork" {
  default = "default"
}

resource "google_container_cluster" "gke_cluster" {
  name                     = "${var.name}"
  zone                     = "${var.zone}"
  min_master_version       = "1.11"
  initial_node_count       = 1
  remove_default_node_pool = true
  network                  = "${var.gke_network}"
  subnetwork               = "${var.gke_subnetwork}"

  ip_allocation_policy {}

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }

    username = "${random_id.username.hex}"
    password = "${random_id.password.hex}"
  }
}

resource "google_container_node_pool" "node_pool" {
  name               = "${var.name}"
  zone               = "${var.zone}"
  initial_node_count = 1
  cluster            = "${google_container_cluster.gke_cluster.name}"

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}

# The following outputs allow authentication and connectivity to the GKE Cluster.
output "endpoint" {
  value = "https://${google_container_cluster.gke_cluster.endpoint}/"
}
