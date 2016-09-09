module "gce_project_1" {
  source = "../modules/gce_project"

  bastion_config = "${file("${path.module}/config/bastion-env")}"
  bastion_image = "${var.gce_bastion_image}"
  env = "${var.env}"
  index = "1"
  nat_image = "${var.gce_nat_image}"
  project = "travis-staging-1"
  worker_account_json_com = "${file("${path.module}/config/gce-workers-staging.json")}"
  worker_account_json_org = "${file("${path.module}/config/gce-workers-staging.json")}"
  worker_chef_json_com = "${file("${path.module}/config/worker-chef-com.json")}"
  worker_chef_json_org = "${file("${path.module}/config/worker-chef-org.json")}"
  worker_config_com = "${file("${path.module}/config/worker-env-com")}"
  worker_config_org = "${file("${path.module}/config/worker-env-org")}"
  worker_image = "${var.gce_worker_image}"
}
