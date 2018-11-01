module "kubernetes_cluster" {
  source                 = "../modules/macstadium_k8s_cluster"
  name_prefix            = "cluster-staging"
  ip_base                = 100
  node_count             = 2
  datacenter             = "pod-1"
  cluster                = "MacPro_Staging_1"
  datastore              = "DataCore1_1"
  internal_network_label = "Internal"
  ssh_user               = "${var.ssh_user}"
}

variable "image_builder_secrets" {
  default = {}
}

module "kubernetes_services" {
  source                 = "services"
  host                   = "${module.kubernetes_cluster.host}"
  cluster_ca_certificate = "${base64decode(module.kubernetes_cluster.cluster_ca_certificate)}"
  client_certificate     = "${base64decode(module.kubernetes_cluster.client_certificate)}"
  client_key             = "${base64decode(module.kubernetes_cluster.client_key)}"
  image_builder_secrets  = "${var.image_builder_secrets}"
}
