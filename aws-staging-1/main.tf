variable "aws_heroku_org" {}

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
variable "syslog_address_com" {}
variable "syslog_address_org" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {}

provider "heroku" {
  version = "0.1.0"
}

data "aws_ami" "tfw" {
  most_recent = true

  filter {
    name   = "tag:role"
    values = ["tfw"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-shared-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

resource "random_id" "cyclist_token_com" {
  byte_length = 32
}

resource "random_id" "cyclist_token_org" {
  byte_length = 32
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
export TRAVIS_WORKER_DOCKER_INSPECT_INTERVAL=1000ms
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
export TRAVIS_WORKER_DOCKER_INSPECT_INTERVAL=1000ms
EOF
}

module "aws_az_1b" {
  source                    = "../modules/aws_workers_az"
  az_group                  = "1b"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1b_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_az_1b2" {
  source                    = "../modules/aws_workers_az"
  az_group                  = "1b2"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1b_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_asg_com" {
  source             = "../modules/aws_asg"
  cyclist_auth_token = "${random_id.cyclist_token_com.hex}"
  cyclist_debug      = "true"
  cyclist_scale      = "web=1:Hobby"
  cyclist_version    = "v0.5.0"
  env                = "${var.env}"
  env_short          = "${var.env}"
  github_users       = "${var.github_users}"
  heroku_org         = "${var.aws_heroku_org}"
  index              = "${var.index}"
  registry_hostname  = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_com_security_group_id}",
    "${module.aws_az_1b2.workers_com_security_group_id}",
  ]

  site                           = "com"
  syslog_address                 = "${var.syslog_address_com}"
  worker_ami                     = "${data.aws_ami.tfw.id}"
  worker_asg_max_size            = 3
  worker_asg_min_size            = 0
  worker_asg_namespace           = "Travis/com-staging"
  worker_asg_scale_in_threshold  = 16
  worker_asg_scale_out_threshold = 8
  worker_config                  = "${data.template_file.worker_config_com.rendered}"
  worker_docker_image_android    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_default    = "${var.latest_docker_image_garnet}"
  worker_docker_image_erlang     = "${var.latest_docker_image_amethyst}"
  worker_docker_image_go         = "${var.latest_docker_image_garnet}"
  worker_docker_image_haskell    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_jvm        = "${var.latest_docker_image_garnet}"
  worker_docker_image_node_js    = "${var.latest_docker_image_garnet}"
  worker_docker_image_perl       = "${var.latest_docker_image_amethyst}"
  worker_docker_image_php        = "${var.latest_docker_image_garnet}"
  worker_docker_image_python     = "${var.latest_docker_image_garnet}"
  worker_docker_image_ruby       = "${var.latest_docker_image_garnet}"
  worker_docker_self_image       = "${var.latest_docker_image_worker}"
  worker_queue                   = "ec2"

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_com_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id}",
  ]
}

module "aws_asg_org" {
  source             = "../modules/aws_asg"
  cyclist_auth_token = "${random_id.cyclist_token_org.hex}"
  cyclist_debug      = "true"
  cyclist_scale      = "web=1:Hobby"
  cyclist_version    = "v0.5.0"
  env                = "${var.env}"
  env_short          = "${var.env}"
  github_users       = "${var.github_users}"
  heroku_org         = "${var.aws_heroku_org}"
  index              = "${var.index}"
  registry_hostname  = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_org_security_group_id}",
    "${module.aws_az_1b2.workers_org_security_group_id}",
  ]

  site                           = "org"
  syslog_address                 = "${var.syslog_address_org}"
  worker_ami                     = "${data.aws_ami.tfw.id}"
  worker_asg_max_size            = 3
  worker_asg_min_size            = 0
  worker_asg_namespace           = "Travis/org-staging"
  worker_asg_scale_in_threshold  = 16
  worker_asg_scale_out_threshold = 8
  worker_config                  = "${data.template_file.worker_config_org.rendered}"
  worker_docker_image_android    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_default    = "${var.latest_docker_image_garnet}"
  worker_docker_image_erlang     = "${var.latest_docker_image_amethyst}"
  worker_docker_image_go         = "${var.latest_docker_image_garnet}"
  worker_docker_image_haskell    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_jvm        = "${var.latest_docker_image_garnet}"
  worker_docker_image_node_js    = "${var.latest_docker_image_garnet}"
  worker_docker_image_perl       = "${var.latest_docker_image_amethyst}"
  worker_docker_image_php        = "${var.latest_docker_image_garnet}"
  worker_docker_image_python     = "${var.latest_docker_image_garnet}"
  worker_docker_image_ruby       = "${var.latest_docker_image_garnet}"
  worker_docker_self_image       = "${var.latest_docker_image_worker}"
  worker_queue                   = "ec2"

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id}",
  ]
}
