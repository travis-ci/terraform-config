provider "kubernetes" {
  host             = "${var.host}"
  load_config_file = false

  cluster_ca_certificate = "${var.cluster_ca_certificate}"
  client_certificate     = "${var.client_certificate}"
  client_key             = "${var.client_key}"
}

