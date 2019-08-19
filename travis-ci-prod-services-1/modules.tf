module "project" {
  source = "../modules/gce_project"

  project_name = "${var.project_name}"
  project_id   = "${var.project_id}"
}

# module "networking" {}
# module "kubernetes_cluster" {}

