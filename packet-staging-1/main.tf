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
variable "librato_email" {}
variable "librato_token" {}
variable "project_id" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

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

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-staging-net-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
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
  source = "../modules/packet_worker"

  bastion_ip                  = "${data.terraform_remote_state.vpc.nat_maint_ip}"
  env                         = "${var.env}"
  facility                    = "${data.terraform_remote_state.vpc.facility}"
  github_users                = "${var.github_users}"
  index                       = "${var.index}"
  nat_ip                      = "${data.terraform_remote_state.vpc.nat_ip}"
  nat_public_ip               = "${data.terraform_remote_state.vpc.nat_public_ip}"
  project_id                  = "${var.project_id}"
  server_count                = 1
  site                        = "com"
  syslog_address              = "${var.syslog_address_com}"
  worker_config               = "${data.template_file.worker_config_com.rendered}"
  worker_docker_image_android = "${var.latest_docker_image_amethyst}"
  worker_docker_image_default = "${var.latest_docker_image_garnet}"
  worker_docker_image_erlang  = "${var.latest_docker_image_amethyst}"
  worker_docker_image_go      = "${var.latest_docker_image_garnet}"
  worker_docker_image_haskell = "${var.latest_docker_image_amethyst}"
  worker_docker_image_jvm     = "${var.latest_docker_image_garnet}"
  worker_docker_image_node_js = "${var.latest_docker_image_garnet}"
  worker_docker_image_perl    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_php     = "${var.latest_docker_image_garnet}"
  worker_docker_image_python  = "${var.latest_docker_image_garnet}"
  worker_docker_image_ruby    = "${var.latest_docker_image_garnet}"
}

module "packet_workers_org" {
  source = "../modules/packet_worker"

  bastion_ip                  = "${data.terraform_remote_state.vpc.nat_maint_ip}"
  env                         = "${var.env}"
  facility                    = "${data.terraform_remote_state.vpc.facility}"
  github_users                = "${var.github_users}"
  index                       = "${var.index}"
  nat_ip                      = "${data.terraform_remote_state.vpc.nat_ip}"
  nat_public_ip               = "${data.terraform_remote_state.vpc.nat_public_ip}"
  project_id                  = "${var.project_id}"
  server_count                = 1
  site                        = "org"
  syslog_address              = "${var.syslog_address_org}"
  worker_config               = "${data.template_file.worker_config_org.rendered}"
  worker_docker_image_android = "${var.latest_docker_image_amethyst}"
  worker_docker_image_default = "${var.latest_docker_image_garnet}"
  worker_docker_image_erlang  = "${var.latest_docker_image_amethyst}"
  worker_docker_image_go      = "${var.latest_docker_image_garnet}"
  worker_docker_image_haskell = "${var.latest_docker_image_amethyst}"
  worker_docker_image_jvm     = "${var.latest_docker_image_garnet}"
  worker_docker_image_node_js = "${var.latest_docker_image_garnet}"
  worker_docker_image_perl    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_php     = "${var.latest_docker_image_garnet}"
  worker_docker_image_python  = "${var.latest_docker_image_garnet}"
  worker_docker_image_ruby    = "${var.latest_docker_image_garnet}"
}
