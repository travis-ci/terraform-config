variable "cluster_name" {
  default = "cluster"
}

variable "pool_name" {
  default = "pool"
}

variable "region" {
  default = "us-central1"
}

variable "gke_network" {
  default = "default"
}

variable "gke_subnetwork" {
  default = "default"
}

variable "k8s_default_namespace" {}

variable "k8s_max_node_count" {
  default = 3
}

variable "k8s_machine_type" {
  default = "n1-standard-1"
}

resource "google_container_cluster" "gke_cluster" {
  name                     = "${var.cluster_name}"
  location                 = "${var.region}"
  min_master_version       = "1.13"
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
  name               = "${var.pool_name}"
  location           = "${var.region}"
  initial_node_count = 1
  cluster            = "${google_container_cluster.gke_cluster.name}"

  node_config {
    machine_type = "${var.k8s_machine_type}"

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
    min_node_count = 1
    max_node_count = "${var.k8s_max_node_count}"
  }
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}

resource "null_resource" "kubectl_context" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --zone ${google_container_cluster.gke_cluster.location} --project ${google_container_cluster.gke_cluster.project}"
  }

  provisioner "local-exec" {
    command = "kubectl config set-context gke_${google_container_cluster.gke_cluster.project}_${google_container_cluster.gke_cluster.location}_${google_container_cluster.gke_cluster.name} --namespace=${var.k8s_default_namespace}"
  }
}

output "context" {
  value = "gke_${google_container_cluster.gke_cluster.project}_${google_container_cluster.gke_cluster.location}_${google_container_cluster.gke_cluster.name}"
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
