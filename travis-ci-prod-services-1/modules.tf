module "project" {
  source = "../modules/gce_project"

  project_name = "${var.project_name}"
  project_id   = "${var.project_id}"
}

module "networking" {
  source = "../modules/gce_net_services"

  project = "${module.project.project_id}"
}

# module "kubernetes_cluster" {}

