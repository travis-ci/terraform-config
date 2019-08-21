module "project" {
  source = "../modules/gce_project"

  project_name = "${var.project_name}"
  project_id   = "${var.project_id}"
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
  subnetwork        = "${module.networking.services_network_name}"

  node_locations       = ["us-central1-b", "us-central1-c"]
  node_pool_tags       = ["services"]
  max_node_count       = 10
  machine_type         = "c2-standard-4"
  enable_private_nodes = true
}
