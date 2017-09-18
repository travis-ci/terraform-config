variable "aws_heroku_org" {}

variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 2
}

variable "rabbitmq_password_com" {}
variable "rabbitmq_password_org" {}
variable "rabbitmq_username_com" {}
variable "rabbitmq_username_org" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "worker_ami" {
  # tfw 2017-09-05 16-00-17
  default = "ami-3e405045"
}

variable "amethyst_image" {
  default = "travisci/ci-amethyst:packer-1503974220"
}

variable "garnet_image" {
  default = "travisci/ci-garnet:packer-1503972846"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-production-2.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-shared-2.tfstate"
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

module "rabbitmq_worker_config_com" {
  source         = "../modules/rabbitmq_user"
  admin_password = "${var.rabbitmq_password_com}"
  admin_username = "${var.rabbitmq_username_com}"
  endpoint       = "https://${trimspace(file("${path.module}/config/CLOUDAMQP_URL_HOST_COM"))}"
  scheme         = "${trimspace(file("${path.module}/config/CLOUDAMQP_URL_SCHEME_COM"))}"
  username       = "travis-worker-ec2-${var.env}-${var.index}"
  vhost          = "${replace(trimspace("${file("${path.module}/config/CLOUDAMQP_URL_PATH_COM")}"), "/^//", "")}"
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

data "template_file" "worker_config_com" {
  template = <<EOF
### config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_com.uri}
export TRAVIS_WORKER_HARD_TIMEOUT=2h
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

export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_org.uri}
export TRAVIS_WORKER_HARD_TIMEOUT=50m0s
export TRAVIS_WORKER_TRAVIS_SITE=org
EOF
}

module "aws_az_1b" {
  source                    = "../modules/aws_workers_az"
  az                        = "1b"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1b_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_az_1e" {
  source                    = "../modules/aws_workers_az"
  az                        = "1e"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1e_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_asg_com" {
  source                                 = "../modules/aws_asg"
  cyclist_auth_token                     = "${random_id.cyclist_token_com.hex}"
  cyclist_version                        = "v0.4.0"
  docker_storage_dm_basesize             = "19G"
  env                                    = "${var.env}"
  env_short                              = "${var.env}"
  github_users                           = "${var.github_users}"
  heroku_org                             = "${var.aws_heroku_org}"
  index                                  = "${var.index}"
  security_groups                        = "${module.aws_az_1b.workers_com_security_group_id},${module.aws_az_1e.workers_com_security_group_id}"
  site                                   = "com"
  syslog_address                         = "${var.syslog_address_com}"
  worker_ami                             = "${var.worker_ami}"
  worker_asg_max_size                    = 200
  worker_asg_min_size                    = 1
  worker_asg_namespace                   = "Travis/com"
  worker_asg_scale_in_threshold          = 120
  worker_asg_scale_in_evaluation_periods = 3
  worker_asg_scale_in_period             = 300
  worker_asg_scale_out_threshold         = 80
  worker_asg_scale_out_qty               = 2
  worker_config                          = "${data.template_file.worker_config_com.rendered}"
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
  worker_queue                           = "ec2"
  worker_subnets                         = "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id},${data.terraform_remote_state.vpc.workers_com_subnet_1e_id}"
}

module "aws_asg_org" {
  source                                 = "../modules/aws_asg"
  cyclist_auth_token                     = "${random_id.cyclist_token_org.hex}"
  cyclist_version                        = "v0.4.0"
  docker_storage_dm_basesize             = "19G"
  env                                    = "${var.env}"
  env_short                              = "${var.env}"
  github_users                           = "${var.github_users}"
  heroku_org                             = "${var.aws_heroku_org}"
  index                                  = "${var.index}"
  security_groups                        = "${module.aws_az_1b.workers_org_security_group_id},${module.aws_az_1e.workers_org_security_group_id}"
  site                                   = "org"
  syslog_address                         = "${var.syslog_address_org}"
  worker_ami                             = "${var.worker_ami}"
  worker_asg_max_size                    = 240
  worker_asg_min_size                    = 1
  worker_asg_namespace                   = "Travis/org"
  worker_asg_scale_in_threshold          = 80
  worker_asg_scale_in_evaluation_periods = 3
  worker_asg_scale_in_period             = 300
  worker_asg_scale_out_threshold         = 60
  worker_asg_scale_out_qty               = 2
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
  worker_queue                           = "ec2"
  worker_subnets                         = "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id},${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}"
}

resource "null_resource" "language_mapping_json" {
  triggers {
    amethyst_image = "${var.amethyst_image}"
    garnet_image   = "${var.garnet_image}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/format-images-json \
  ${var.amethyst_image}=android,erlang,haskell,perl \
  ${var.garnet_image}=default,go,jvm,node_js,php,python,ruby \
  >${path.module}/generated-language-mapping.json
EOF
  }
}

# cs50 {

variable "cs50_image" {
  default = "cs50/travis-ci:latest"
}

resource "random_id" "cyclist_token_cs50" {
  byte_length = 32
}

data "template_file" "worker_config_cs50" {
  template = <<EOF
### config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_com.uri}
export TRAVIS_WORKER_BUILD_PARANOID=true
export TRAVIS_WORKER_DOCKER_ENDPOINT=unix:///var/run/docker.sock
export TRAVIS_WORKER_DOCKER_NATIVE=true
export TRAVIS_WORKER_HARD_TIMEOUT=2h
export TRAVIS_WORKER_POOL_SIZE=4
export TRAVIS_WORKER_PPROF_PORT=6060
export TRAVIS_WORKER_PROVIDER_NAME=docker
export TRAVIS_WORKER_QUEUE_NAME=builds.cs50
export TRAVIS_WORKER_QUEUE_TYPE=amqp
export TRAVIS_WORKER_TRAVIS_SITE=com
EOF
}

module "aws_asg_cs50" {
  source                         = "../modules/aws_asg"
  cyclist_auth_token             = "${random_id.cyclist_token_cs50.hex}"
  cyclist_version                = "v0.4.0"
  env                            = "cs50-${var.env}"
  env_short                      = "${var.env}"
  github_users                   = "${var.github_users}"
  heroku_org                     = "${var.aws_heroku_org}"
  index                          = "${var.index}"
  security_groups                = "${module.aws_az_1b.workers_com_security_group_id},${module.aws_az_1e.workers_com_security_group_id}"
  site                           = "com"
  syslog_address                 = "${var.syslog_address_com}"
  worker_ami                     = "${var.worker_ami}"
  worker_asg_max_size            = 1
  worker_asg_min_size            = 1
  worker_asg_namespace           = "Travis/com-cs50"
  worker_asg_scale_in_threshold  = 4
  worker_asg_scale_out_threshold = 4
  worker_asg_scale_out_qty       = 1
  worker_config                  = "${data.template_file.worker_config_cs50.rendered}"
  worker_docker_image_android    = "${var.cs50_image}"
  worker_docker_image_default    = "${var.cs50_image}"
  worker_docker_image_erlang     = "${var.cs50_image}"
  worker_docker_image_go         = "${var.cs50_image}"
  worker_docker_image_haskell    = "${var.cs50_image}"
  worker_docker_image_jvm        = "${var.cs50_image}"
  worker_docker_image_node_js    = "${var.cs50_image}"
  worker_docker_image_perl       = "${var.cs50_image}"
  worker_docker_image_php        = "${var.cs50_image}"
  worker_docker_image_python     = "${var.cs50_image}"
  worker_docker_image_ruby       = "${var.cs50_image}"
  worker_instance_type           = "c3.2xlarge"
  worker_queue                   = "cs50"
  worker_subnets                 = "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id},${data.terraform_remote_state.vpc.workers_com_subnet_1e_id}"
}

# } cs50

