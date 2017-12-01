variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}

variable "env" {
  default = "staging"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "latest_docker_image_amethyst" {}
variable "latest_docker_image_garnet" {}
variable "latest_docker_image_worker" {}
variable "packet_staging_1_project_id" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.0.2"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "packet" {}
provider "aws" {}

module "packet_network_ewr1" {
  source              = "../modules/packet_network"
  duo_api_hostname    = "${var.duo_api_hostname}"
  duo_integration_key = "${var.duo_integration_key}"
  duo_secret_key      = "${var.duo_secret_key}"
  env                 = "${var.env}"
  facility            = "ewr1"
github_users = "${var.github_users}"
  index               = "${var.index}"
}

data "template_file" "worker_config_com" {
  template = <<EOF
### config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_TRAVIS_SITE=com
EOF
}

data "template_file" "worker_config_org" {
  template = <<EOF
### config/worker-org-local.env
${file("${path.module}/config/worker-org-local.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_TRAVIS_SITE=org
EOF
}

module "packet_workers_com" {
  source         = "../modules/packet_worker"
  env            = "${var.env}"
  facility       = "${module.packet_network_ewr1.facility}"
  index          = "${var.index}"
  network_config = "${data.template_file.network_config.rendered}"
  nat_ip         = "${module.packet_network_ewr1.nat_ip}"
  worker_config  = "${data.template_file.worker_config_com.rendered}"
  server_count   = 1
  site           = "com"
  project_id     = "${var.packet_staging_1_project_id}"
}

module "packet_workers_org" {
  source         = "../modules/packet_worker"
  env            = "${var.env}"
  facility       = "${module.packet_network_ewr1.facility}"
  index          = "${var.index}"
  network_config = "${data.template_file.network_config.rendered}"
  nat_ip         = "${module.packet_network_ewr1.nat_ip}"
  worker_config  = "${data.template_file.worker_config_org.rendered}"
  server_count   = 1
  site           = "org"
  project_id     = "${var.packet_staging_1_project_id}"
}

resource "aws_route53_record" "workers_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-${var.env}-${var.index}.packet-ewr1.travisci.net"
  type    = "A"
  ttl     = 300

  records = ["${module.packet_network_ewr1.nat_public_ip}"]
}
