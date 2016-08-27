module "gce_project_1" {
  source = "../modules/gce_project"

  env = "${var.env}"
  index = "1"

  gce_project = "travis-staging-1"
  gce_bastion_image = "${var.gce_bastion_image}"
  gce_nat_image = "${var.gce_nat_image}"
  gce_worker_image = "${var.gce_worker_image}"

  gce_worker_cloud_init_org = "${template_file.worker_cloud_init_org.rendered}"
  gce_worker_cloud_init_com = "${template_file.worker_cloud_init_com.rendered}"
  bastion_cloud_init = "${template_file.bastion_cloud_init.rendered}"
}
