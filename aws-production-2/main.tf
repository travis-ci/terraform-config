variable "aws_heroku_org" {}
variable "env" { default = "production" }
variable "github_users" {}
variable "index" { default = 2 }
variable "rabbitmq_password_com" {}
variable "rabbitmq_password_org" {}
variable "rabbitmq_username_com" {}
variable "rabbitmq_username_org" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "worker_ami" { default = "ami-a19d9bb6" }

provider "aws" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "travis-terraform-state"
    key = "terraform-config/aws-shared-2.tfstate"
    region = "us-east-1"
  }
}

resource "random_id" "cyclist_token_com" { byte_length = 32 }
resource "random_id" "cyclist_token_org" { byte_length = 32 }

module "rabbitmq_worker_config_com" {
  source = "../modules/rabbitmq_user"
  admin_password = "${var.rabbitmq_password_com}"
  admin_username = "${var.rabbitmq_username_com}"
  endpoint = "https://${trimspace(file("${path.module}/config/CLOUDAMQP_URL_HOST_COM"))}"
  scheme = "${trimspace(file("${path.module}/config/CLOUDAMQP_URL_SCHEME_COM"))}"
  username = "travis-worker-ec2-${var.env}-${var.index}"
  vhost = "${replace(trimspace("${file("${path.module}/config/CLOUDAMQP_URL_PATH_COM")}"), "/^//", "")}"
}

module "rabbitmq_worker_config_org" {
  source = "../modules/rabbitmq_user"
  admin_password = "${var.rabbitmq_password_org}"
  admin_username = "${var.rabbitmq_username_org}"
  endpoint = "https://${trimspace(file("${path.module}/config/CLOUDAMQP_URL_HOST_ORG"))}"
  scheme = "${trimspace(file("${path.module}/config/CLOUDAMQP_URL_SCHEME_ORG"))}"
  username = "travis-worker-ec2-${var.env}-${var.index}"
  vhost = "${replace(trimspace("${file("${path.module}/config/CLOUDAMQP_URL_PATH_ORG")}"), "/^//", "")}"
}

data "template_file" "worker_config_com" {
  template = <<EOF
### ${path.module}/config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### ${path.module}/config/worker-com.env
${file("${path.module}/config/worker-com.env")}
### ${path.module}/worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_HARD_TIMEOUT=2h
export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_com.uri}
EOF
}

data "template_file" "worker_config_org" {
  template = <<EOF
### ${path.module}/config/worker-org-local.env
${file("${path.module}/config/worker-org-local.env")}
### ${path.module}/config/worker-org.env
${file("${path.module}/config/worker-org.env")}
### ${path.module}/worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_HARD_TIMEOUT=50m0s
export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_org.uri}
EOF
}

module "aws_az_1b" {
  source = "../modules/aws_workers_az"
  az = "1b"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1b_id}"
  env = "${var.env}"
  index = "${var.index}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_az_1e" {
  source = "../modules/aws_workers_az"
  az = "1e"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1e_id}"
  env = "${var.env}"
  index = "${var.index}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_asg_com" {
  source = "../modules/aws_asg"
  cyclist_auth_token = "${random_id.cyclist_token_com.hex}"
  cyclist_version = "v0.4.0"
  docker_storage_dm_basesize = "19G"
  env = "${var.env}"
  env_short = "${var.env}"
  github_users = "${var.github_users}"
  heroku_org = "${var.aws_heroku_org}"
  index = "${var.index}"
  security_groups = "${module.aws_az_1b.workers_com_security_group_id},${module.aws_az_1e.workers_com_security_group_id}"
  site = "com"
  syslog_address = "${var.syslog_address_com}"
  worker_ami = "${var.worker_ami}"
  # NOTE: builds.docker value for com production
  # worker_asg_max_size = 100
  worker_asg_max_size = 20
  worker_asg_min_size = 1
  worker_asg_namespace = "Travis/com"
  # NOTE: builds.docker values for com production
  # worker_asg_scale_in_threshold = 100
  # worker_asg_scale_out_threshold = 60
  worker_asg_scale_in_threshold = 50
  worker_asg_scale_out_qty = 2
  worker_asg_scale_out_threshold = 30
  worker_config = "${data.template_file.worker_config_com.rendered}"
  worker_docker_image_android = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_default = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_erlang = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_go = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_haskell = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_jvm = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_node_js = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_perl = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_php = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_python = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_ruby = "travisci/ci-garnet:packer-1478744932"
  worker_docker_self_image = "quay.io/travisci/worker:v2.5.0-8-g19ea9c2"
  worker_instance_type = "c3.8xlarge"
  worker_queue = "ec2"
  worker_subnets = "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id},${data.terraform_remote_state.vpc.workers_com_subnet_1e_id}"
}

module "aws_asg_org" {
  source = "../modules/aws_asg"
  cyclist_auth_token = "${random_id.cyclist_token_org.hex}"
  cyclist_version = "v0.4.0"
  docker_storage_dm_basesize = "19G"
  env = "${var.env}"
  env_short = "${var.env}"
  github_users = "${var.github_users}"
  heroku_org = "${var.aws_heroku_org}"
  index = "${var.index}"
  security_groups = "${module.aws_az_1b.workers_org_security_group_id},${module.aws_az_1e.workers_org_security_group_id}"
  site = "org"
  syslog_address = "${var.syslog_address_org}"
  worker_ami = "${var.worker_ami}"
  # NOTE: builds.docker value for org production
  # worker_asg_max_size = 75
  worker_asg_max_size = 20
  worker_asg_min_size = 1
  worker_asg_namespace = "Travis/org"
  # NOTE: builds.docker values for org production
  # worker_asg_scale_in_threshold = 64
  # worker_asg_scale_out_threshold = 48
  worker_asg_scale_in_threshold = 50
  worker_asg_scale_out_qty = 2
  worker_asg_scale_out_threshold = 30
  worker_config = "${data.template_file.worker_config_org.rendered}"
  worker_docker_image_android = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_default = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_erlang = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_go = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_haskell = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_jvm = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_node_js = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_perl = "travisci/ci-amethyst:packer-1478744929"
  worker_docker_image_php = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_python = "travisci/ci-garnet:packer-1478744932"
  worker_docker_image_ruby = "travisci/ci-garnet:packer-1478744932"
  worker_docker_self_image = "quay.io/travisci/worker:v2.5.0-8-g19ea9c2"
  worker_instance_type = "c3.8xlarge"
  worker_queue = "ec2"
  worker_subnets = "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id},${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}"
}
