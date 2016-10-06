variable "aws_heroku_org" {}
variable "env" { default = "staging" }
variable "index" { default = 1 }
variable "syslog_address" {}
variable "worker_ami" { default = "ami-c6710cd1" }
variable "worker_com_cache_bucket" {}
variable "worker_org_cache_bucket" {}

provider "aws" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "travis-terraform-state"
    key = "terraform-config/aws-shared-1.tfstate"
    region = "us-east-1"
  }
}

resource "random_id" "cyclist_token_com" { byte_length = 32 }
resource "random_id" "cyclist_token_org" { byte_length = 32 }

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
  cyclist_debug = "true"
  cyclist_scale = "web=1:Hobby"
  cyclist_version = "v0.1.0"
  env = "${var.env}"
  env_short = "${var.env}"
  heroku_org = "${var.aws_heroku_org}"
  index = "${var.index}"
  security_groups = "${module.aws_az_1b.workers_com_security_group_id},${module.aws_az_1e.workers_com_security_group_id}"
  site = "com"
  syslog_address = "${var.syslog_address}"
  worker_ami = "${var.worker_ami}"
  worker_asg_max_size = 1
  worker_asg_min_size = 0
  worker_asg_namespace = "Travis/com-staging"
  worker_asg_scale_in_threshold = 16
  worker_asg_scale_out_threshold = 8
  worker_cache_bucket = "${var.worker_com_cache_bucket}"
  worker_config = <<EOF
### ${path.module}/config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### ${path.module}/config/worker-com.env
${file("${path.module}/config/worker-com.env")}
### ${path.module}/worker.env
${file("${path.module}/worker.env")}
EOF
  worker_docker_image_android = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_default = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_erlang = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_go = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_haskell = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_jvm = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_node_js = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_perl = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_php = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_python = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_ruby = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_self_image = "quay.io/travisci/worker:v2.4.0-23-g396d039"
  worker_queue = "ec2"
  worker_subnets = "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id},${data.terraform_remote_state.vpc.workers_com_subnet_1e_id}"
}

module "aws_asg_org" {
  source = "../modules/aws_asg"
  cyclist_auth_token = "${random_id.cyclist_token_org.hex}"
  cyclist_debug = "true"
  cyclist_scale = "web=1:Hobby"
  cyclist_version = "v0.1.0"
  env = "${var.env}"
  env_short = "${var.env}"
  heroku_org = "${var.aws_heroku_org}"
  index = "${var.index}"
  security_groups = "${module.aws_az_1b.workers_org_security_group_id},${module.aws_az_1e.workers_org_security_group_id}"
  site = "org"
  syslog_address = "${var.syslog_address}"
  worker_ami = "${var.worker_ami}"
  worker_asg_max_size = 3
  worker_asg_min_size = 0
  worker_asg_namespace = "Travis/org-staging"
  worker_asg_scale_in_threshold = 16
  worker_asg_scale_out_threshold = 8
  worker_cache_bucket = "${var.worker_org_cache_bucket}"
  worker_config = <<EOF
### ${path.module}/config/worker-org-local.env
${file("${path.module}/config/worker-org-local.env")}
### ${path.module}/config/worker-org.env
${file("${path.module}/config/worker-org.env")}
### ${path.module}/worker.env
${file("${path.module}/worker.env")}
EOF
  worker_docker_image_android = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_default = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_erlang = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_go = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_haskell = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_jvm = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_node_js = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_perl = "quay.io/travisci/ci-amethyst:packer-1473386113"
  worker_docker_image_php = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_python = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_image_ruby = "quay.io/travisci/ci-garnet:packer-1473395986"
  worker_docker_self_image = "quay.io/travisci/worker:v2.4.0-23-g396d039"
  worker_queue = "ec2"
  worker_subnets = "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id},${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}"
}
