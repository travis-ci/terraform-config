variable "env" { default = "staging" }
variable "gce_bastion_image" { default = "eco-emissary-99515/bastion-1478778272" }
variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}
variable "gce_nat_image" { default = "eco-emissary-99515/nat-1478778271" }
variable "gce_hashistack_server_image" { default = "eco-emissary-99515/hashistack-server-1480351044" }
variable "gce_worker_image" { default = "eco-emissary-99515/travis-worker-1480649763" }
variable "github_users" {}
variable "index" { default = 1 }
variable "job_board_url" {}
variable "travisci_net_external_zone_id" { default = "Z2RI61YP4UWSIO" }
variable "syslog_address_com" {}
variable "syslog_address_org" {}

provider "google" {
  project = "travis-staging-1"
}

provider "aws" {}

provider "heroku" {}

data "template_file" "hashistack_server_cloud_init" {
  template = "${file("${path.module}/hashistack-server-init.tpl")}"
  vars {
    hashistack_server_config = "${file("${path.module}/config/hashistack-server-env")}"
  }
}

module "hashistack_server" {
  source = "../modules/hashistack_server"
  cloud_init = "${data.template_file.hashistack_server_cloud_init.rendered}"
  env = "${var.env}"
  gce_network = "${module.gce_project_1.gce_network}"
  gce_project = "travis-staging-1"
  gce_subnetwork = "${module.gce_project_1.gce_subnetwork_public}"
  gce_zone = "us-central1-b"
  gce_zone_suffix = "b"
  index = 1
  instance_count = 3
  hashistack_server_image = "${var.gce_hashistack_server_image}"
}

resource "aws_route53_record" "hashistack_server" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "hashistack-server.gce-us-central1-b.travisci.net"
  type = "A"
  ttl = 5
  records = [
    "${module.hashistack_server.hashistack_server_ip}"
  ]
}

module "gce_project_1" {
  source = "../modules/gce_project"
  bastion_config = "${file("${path.module}/config/bastion-env")}"
  bastion_image = "${var.gce_bastion_image}"
  env = "${var.env}"
  github_users = "${var.github_users}"
  gcloud_cleanup_account_json = "${file("${path.module}/config/gce-cleanup-staging-1.json")}"
  gcloud_cleanup_job_board_url = "${var.job_board_url}"
  gcloud_cleanup_loop_sleep = "2m"
  gcloud_cleanup_scale = "worker=1:Hobby"
  gcloud_zone = "${var.gce_gcloud_zone}"
  heroku_org = "${var.gce_heroku_org}"
  index = "${var.index}"
  nat_image = "${var.gce_nat_image}"
  nat_machine_type = "g1-small"
  project = "travis-staging-1"
  syslog_address_com = "${var.syslog_address_com}"
  syslog_address_org = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  worker_account_json_com = "${file("${path.module}/config/gce-workers-staging-1.json")}"
  worker_account_json_org = "${file("${path.module}/config/gce-workers-staging-1.json")}"
  worker_config_com = "${file("${path.module}/config/worker-env-com")}"
  worker_config_org = "${file("${path.module}/config/worker-env-org")}"
  worker_docker_self_image = "travisci/worker:v2.6.1"
  worker_image = "${var.gce_worker_image}"
  # instance count must be a multiple of number of zones (currently 2)
  worker_instance_count_com = 2
  worker_instance_count_org = 2
}
