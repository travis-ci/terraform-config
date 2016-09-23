provider "aws" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "travis-terraform-state"
    key = "terraform-config/aws-shared-1.tfstate"
    region = "us-east-1"
  }
}

module "aws_az_1b" {
  source = "../modules/aws_workers_az"

  az = "1b"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_id_1b}"
  env = "${var.env}"
  gateway_id = "${data.terraform_remote_state.vpc.gateway_id}"
  index = "${var.index}"
  nat_id = "${data.terraform_remote_state.vpc.nat_id_1b}"
  public_subnet = "${data.terraform_remote_state.vpc.public_subnet_1b}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  workers_com_subnet = "${data.terraform_remote_state.vpc.workers_com_subnet_1b}"
  workers_org_subnet = "${data.terraform_remote_state.vpc.workers_org_subnet_1b}"
}

module "aws_az_1e" {
  source = "../modules/aws_workers_az"

  az = "1e"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_id_1e}"
  env = "${var.env}"
  gateway_id = "${data.terraform_remote_state.vpc.gateway_id}"
  index = "${var.index}"
  nat_id = "${data.terraform_remote_state.vpc.nat_id_1e}"
  public_subnet = "${data.terraform_remote_state.vpc.public_subnet_1e}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  workers_com_subnet = "${data.terraform_remote_state.vpc.workers_com_subnet_1e}"
  workers_org_subnet = "${data.terraform_remote_state.vpc.workers_org_subnet_1e}"
}

module "aws_asg_org" {
  source = "../modules/aws_asg"

  cyclist_auth_tokens = "${var.cyclist_auth_tokens}"
  cyclist_debug = "true"
  cyclist_scale = "web=1:Hobby"
  cyclist_version = "v0.1.0"
  env = "${var.env}"
  heroku_org = "${var.aws_heroku_org}"
  index = "${var.index}"
  security_groups = "${module.aws_az_1b.workers_org_security_group_id},${module.aws_az_1e.workers_org_security_group_id}"
  site = "org"
  syslog_address = "${var.syslog_address}"
  worker_ami = "ami-c6710cd1"
  worker_asg_max_size = "1"
  worker_asg_min_size = "1"
  worker_asg_namespace = "Travis/org-staging"
  worker_asg_scale_in_threshold = "16"
  worker_asg_scale_out_threshold = "8"
  worker_config = "${file("${path.module}/config/worker-env-org")}"
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
  worker_subnets = "${module.aws_az_1b.workers_org_subnet_id},${module.aws_az_1e.workers_org_subnet_id}"
}

module "aws_asg_com" {
  source = "../modules/aws_asg"

  cyclist_auth_tokens = "${var.cyclist_auth_tokens}"
  cyclist_debug = "true"
  cyclist_scale = "web=1:Hobby"
  cyclist_version = "v0.1.0"
  env = "${var.env}"
  heroku_org = "${var.aws_heroku_org}"
  index = "${var.index}"
  security_groups = "${module.aws_az_1b.workers_com_security_group_id},${module.aws_az_1e.workers_com_security_group_id}"
  site = "com"
  syslog_address = "${var.syslog_address}"
  worker_ami = "ami-c6710cd1"
  worker_asg_max_size = "1"
  worker_asg_min_size = "1"
  worker_asg_namespace = "Travis/com-staging"
  worker_asg_scale_in_threshold = "16"
  worker_asg_scale_out_threshold = "8"
  worker_config = "${file("${path.module}/config/worker-env-com")}"
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
  worker_subnets = "${module.aws_az_1b.workers_com_subnet_id},${module.aws_az_1e.workers_com_subnet_id}"
}
