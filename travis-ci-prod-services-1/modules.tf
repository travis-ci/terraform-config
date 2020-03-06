module "project" {
  source = "../modules/gce_project"

  project_id = "${var.project_id}"
}

module "networking" {
  source = "../modules/gce_net_services"

  project = "${module.project.project_id}"
}

module "kubernetes_cluster" {
  source = "../modules/gce_kubernetes"

  cluster_name      = "travis-ci-services"
  default_namespace = "default"
  network           = "${module.networking.main_network_name}"
  pool_name         = "pool1"
  project           = "${module.project.project_id}"
  region            = "${var.region}"
  subnetwork        = "${module.networking.services_network_name_us_east1}"

  node_locations                 = ["us-east1-b", "us-east1-c", "us-east1-d"]
  node_pool_tags                 = ["services"]
  min_node_count                 = 2
  max_node_count                 = 50
  machine_type                   = "c2-standard-8"
  enable_private_nodes           = true
  private_master_ipv4_cidr_block = "172.16.0.0/28"
  min_master_version             = "1.15"
}

// Use these outputs to be able to easily set up a context in kubectl on the local machine.
output "cluster_host" {
  value = "${module.kubernetes_cluster.host}"
}

output "cluster_ca_certificate" {
  value     = "${module.kubernetes_cluster.cluster_ca_certificate}"
  sensitive = true
}

output "client_certificate" {
  value     = "${module.kubernetes_cluster.client_certificate}"
  sensitive = true
}

output "client_key" {
  value     = "${module.kubernetes_cluster.client_key}"
  sensitive = true
}

output "context" {
  value = "${module.kubernetes_cluster.context}"
}

module "kubernetes_cluster_us_east4" {
  source = "../modules/gce_kubernetes"

  cluster_name      = "travis-ci-services-1"
  default_namespace = "default"
  network           = "${module.networking.main_network_name}"
  pool_name         = "pool1"
  project           = "${module.project.project_id}"
  region            = "us-east4"
  subnetwork        = "${module.networking.services_network_name_us_east4}"

  node_locations                 = ["us-east4-b", "us-east4-a", "us-east4-c"]
  node_pool_tags                 = ["services"]
  min_node_count                 = 4
  max_node_count                 = 50
  machine_type                   = "n1-standard-4"
  enable_private_nodes           = true
  private_master_ipv4_cidr_block = "172.16.0.16/28"
  min_master_version             = "1.15"
}

// Use these outputs to be able to easily set up a context in kubectl on the local machine.
output "cluster_host_us_east4" {
  value = "${module.kubernetes_cluster_us_east4.host}"
}

output "cluster_ca_certificate_us_east4" {
  value     = "${module.kubernetes_cluster_us_east4.cluster_ca_certificate}"
  sensitive = true
}

output "client_certificate_us_east4" {
  value     = "${module.kubernetes_cluster_us_east4.client_certificate}"
  sensitive = true
}

output "client_key_us_east4" {
  value     = "${module.kubernetes_cluster_us_east4.client_key}"
  sensitive = true
}

output "context_us_east4" {
  value = "${module.kubernetes_cluster_us_east4.context}"
}
