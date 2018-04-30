variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "librato_email" {}
variable "librato_token" {}
variable "project_id" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "amethyst_image" {
  default = "travisci/ci-amethyst:packer-1512508255-986baf0"
}

variable "garnet_image" {
  default = "travisci/ci-garnet:packer-1512502276-986baf0"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-production-1.tfstate"
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
    key            = "terraform-config/packet-production-net-1.tfstate"
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
  librato_email               = "${var.librato_email}"
  librato_token               = "${var.librato_token}"
  nat_ips                     = ["${data.terraform_remote_state.vpc.nat_ips}"]
  nat_public_ips              = ["${data.terraform_remote_state.vpc.nat_public_ips}"]
  project_id                  = "${var.project_id}"
  server_count                = 1
  site                        = "com"
  syslog_address              = "${var.syslog_address_com}"
  terraform_privkey           = "${data.terraform_remote_state.vpc.terraform_privkey}"
  worker_config               = "${data.template_file.worker_config_com.rendered}"
  worker_docker_image_android = "${var.amethyst_image}"
  worker_docker_image_default = "${var.garnet_image}"
  worker_docker_image_erlang  = "${var.amethyst_image}"
  worker_docker_image_go      = "${var.garnet_image}"
  worker_docker_image_haskell = "${var.amethyst_image}"
  worker_docker_image_jvm     = "${var.garnet_image}"
  worker_docker_image_node_js = "${var.garnet_image}"
  worker_docker_image_perl    = "${var.amethyst_image}"
  worker_docker_image_php     = "${var.garnet_image}"
  worker_docker_image_python  = "${var.garnet_image}"
  worker_docker_image_ruby    = "${var.garnet_image}"
}

module "packet_workers_org" {
  source = "../modules/packet_worker"

  bastion_ip                  = "${data.terraform_remote_state.vpc.nat_maint_ip}"
  env                         = "${var.env}"
  facility                    = "${data.terraform_remote_state.vpc.facility}"
  github_users                = "${var.github_users}"
  index                       = "${var.index}"
  librato_email               = "${var.librato_email}"
  librato_token               = "${var.librato_token}"
  nat_ips                     = ["${data.terraform_remote_state.vpc.nat_ips}"]
  nat_public_ips              = ["${data.terraform_remote_state.vpc.nat_public_ips}"]
  project_id                  = "${var.project_id}"
  server_count                = 1
  site                        = "org"
  syslog_address              = "${var.syslog_address_org}"
  terraform_privkey           = "${data.terraform_remote_state.vpc.terraform_privkey}"
  worker_config               = "${data.template_file.worker_config_org.rendered}"
  worker_docker_image_android = "${var.amethyst_image}"
  worker_docker_image_default = "${var.garnet_image}"
  worker_docker_image_erlang  = "${var.amethyst_image}"
  worker_docker_image_go      = "${var.garnet_image}"
  worker_docker_image_haskell = "${var.amethyst_image}"
  worker_docker_image_jvm     = "${var.garnet_image}"
  worker_docker_image_node_js = "${var.garnet_image}"
  worker_docker_image_perl    = "${var.amethyst_image}"
  worker_docker_image_php     = "${var.garnet_image}"
  worker_docker_image_python  = "${var.garnet_image}"
  worker_docker_image_ruby    = "${var.garnet_image}"
}
