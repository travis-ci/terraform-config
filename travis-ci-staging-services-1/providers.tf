provider "google" {
  region = "${var.region}"
}

provider "kubernetes" {
  host                   = "${module.kubernetes_cluster.host}"
  client_certificate     = "${module.kubernetes_cluster.client_certificate}"
  client_key             = "${module.kubernetes_cluster.client_key}"
  cluster_ca_certificate = "${module.kubernetes_cluster.cluster_ca_certificate}"

  # Imports don't work with client certificates, provide kubectl context for this instead.
  #config_context = ""
}
