module "vault_consul" {
  source = "../modules/vault_consul"

  env = "${var.env}"
  index = "1"

  gce_zone = "us-central1-b"
  gce_zone_suffix = "b" 
  gce_project = "travis-staging-1"
  gce_network = "${module.gce_project_1.gce_network}"
  gce_subnetwork = "${module.gce_project_1.gce_subnetwork_public}"
  vault_consul_image = "${var.gce_vault_consul_image}"
  instance_count = 3

  cloud_init = "${data.template_file.vault_consul_cloud_init.rendered}"
}