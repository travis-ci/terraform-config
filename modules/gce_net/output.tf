output "gce_network_main" {
  value = "${google_compute_network.main.self_link}"
}

output "gce_subnetwork_public" {
  value = "${google_compute_subnetwork.public.self_link}"
}

output "gce_subnetwork_workers" {
  value = "${google_compute_subnetwork.workers.self_link}"
}

output "gce_subnetwork_gke_cluster" {
  value = "${google_compute_subnetwork.gke_cluster.self_link}"
}
