variable "aws_heroku_org" {}

variable "env" {
  default = "enigma"
}

variable "github_users" {}

variable "index" {
  default = 2
}

variable "rabbitmq_password_org" {}

variable "rabbitmq_username_org" {}

variable "syslog_address_org" {}

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

variable "amethyst_image" {
  default = "travisci/ci-amethyst:packer-1512508255-986baf0"
}

variable "garnet_image" {
  default = "travisci/ci-garnet:packer-1512502276-986baf0"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-enigma-2.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {
  version = "~> 1.4"
}

provider "heroku" {
  version = "0.1.0"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-shared-2.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

resource "random_id" "cyclist_token_org" {
  byte_length = 32
}

module "rabbitmq_worker_config_org" {
  source         = "../modules/rabbitmq_user"
  admin_password = "${var.rabbitmq_password_org}"
  admin_username = "${var.rabbitmq_username_org}"
  endpoint       = "https://${trimspace(file("${path.module}/config/CLOUDAMQP_URL_HOST_ORG"))}"
  scheme         = "${trimspace(file("${path.module}/config/CLOUDAMQP_URL_SCHEME_ORG"))}"
  username       = "travis-worker-ec2-${var.env}-${var.index}"
  vhost          = "${replace(trimspace("${file("${path.module}/config/CLOUDAMQP_URL_PATH_ORG")}"), "/^//", "")}"
}

data "template_file" "worker_config_org" {
  template = <<EOF
### config/worker-org-local.env
${file("${path.module}/config/worker-org-local.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_org.uri}
export TRAVIS_WORKER_HARD_TIMEOUT=50m0s
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

module "aws_az_1e" {
  source                    = "../modules/aws_workers_az"
  az_group                  = "1e"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1e_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_asg_org" {
  source                     = "../modules/aws_asg"
  cyclist_auth_token         = "${random_id.cyclist_token_org.hex}"
  cyclist_version            = "v0.5.0"
  docker_storage_dm_basesize = "19G"
  env                        = "${var.env}"
  env_short                  = "${var.env}"
  github_users               = "${var.github_users}"
  heroku_org                 = "${var.aws_heroku_org}"
  index                      = "${var.index}"
  registry_hostname          = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_org_security_group_id}",
    "${module.aws_az_1e.workers_org_security_group_id}",
  ]

  site                                   = "org"
  syslog_address                         = "${var.syslog_address_org}"
  worker_ami                             = "${data.aws_ami.tfw.id}"
  worker_asg_max_size                    = 2
  worker_asg_min_size                    = 2
  worker_asg_namespace                   = "Travis/org"
  worker_asg_scale_in_threshold          = 3
  worker_asg_scale_in_evaluation_periods = 3
  worker_asg_scale_in_period             = 300
  worker_asg_scale_out_threshold         = 1
  worker_asg_scale_out_qty               = 0
  worker_config                          = "${data.template_file.worker_config_org.rendered}"
  worker_docker_image_android            = "${var.amethyst_image}"
  worker_docker_image_default            = "${var.garnet_image}"
  worker_docker_image_erlang             = "${var.amethyst_image}"
  worker_docker_image_go                 = "${var.garnet_image}"
  worker_docker_image_haskell            = "${var.amethyst_image}"
  worker_docker_image_jvm                = "${var.garnet_image}"
  worker_docker_image_node_js            = "${var.garnet_image}"
  worker_docker_image_perl               = "${var.amethyst_image}"
  worker_docker_image_php                = "${var.garnet_image}"
  worker_docker_image_python             = "${var.garnet_image}"
  worker_docker_image_ruby               = "${var.garnet_image}"
  worker_instance_type                   = "c3.8xlarge"
  worker_queue                           = "enigma"

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}",
  ]
}
