resource "null_resource" "kubectl_context" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --zone ${google_container_cluster.gke_cluster.location} --project ${google_container_cluster.gke_cluster.project}"
  }

  provisioner "local-exec" {
    command = "kubectl config set-context gke_${google_container_cluster.gke_cluster.project}_${google_container_cluster.gke_cluster.location}_${google_container_cluster.gke_cluster.name} --namespace=${var.default_namespace}"
  }
}

output "context" {
  value = "gke_${google_container_cluster.gke_cluster.project}_${google_container_cluster.gke_cluster.location}_${google_container_cluster.gke_cluster.name}"
}
