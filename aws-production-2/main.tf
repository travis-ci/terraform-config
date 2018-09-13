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
  # tfw 2018-03-08 00-09-18
  default = "ami-07dd1aada92124d1e"
}

variable "worker_ami_canary" {
  # tfw 2018-03-08 00-09-18
  default = "ami-07dd1aada92124d1e"
}

variable "amethyst_image" {
  default = "travisci/ci-amethyst:packer-1512508255-986baf0"
}

variable "garnet_image" {
  default = "travisci/ci-garnet:packer-1512502276-986baf0"
}

variable "worker_image_canary" {
  default = "travisci/worker:v3.8.2"
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

resource "random_id" "cyclist_token_com" {
  byte_length = 32
}

resource "random_id" "cyclist_token_org" {
  byte_length = 32
}

module "rabbitmq_worker_config_com" {
  source = "../modules/rabbitmq_user"

  admin_password = "${var.rabbitmq_password_com}"
  admin_username = "${var.rabbitmq_username_com}"
  endpoint       = "https://${trimspace(file("${path.module}/config/CLOUDAMQP_URL_HOST_COM"))}"
  scheme         = "${trimspace(file("${path.module}/config/CLOUDAMQP_URL_SCHEME_COM"))}"
  username       = "travis-worker-ec2-${var.env}-${var.index}"
  vhost          = "${replace(trimspace("${file("${path.module}/config/CLOUDAMQP_URL_PATH_COM")}"), "/^//", "")}"
}

module "rabbitmq_worker_config_org" {
  source = "../modules/rabbitmq_user"

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

export TRAVIS_WORKER_QUEUE_NAME=builds.ec2
export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_com.uri}
export TRAVIS_WORKER_HARD_TIMEOUT=2h
export TRAVIS_WORKER_TRAVIS_SITE=com

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

data "template_file" "worker_config_com_free" {
  template = <<EOF
### config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.ec2-free
export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_com.uri}
export TRAVIS_WORKER_HARD_TIMEOUT=2h
export TRAVIS_WORKER_TRAVIS_SITE=com

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
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

export TRAVIS_WORKER_QUEUE_NAME=builds.ec2
export TRAVIS_WORKER_AMQP_URI=${module.rabbitmq_worker_config_org.uri}
export TRAVIS_WORKER_HARD_TIMEOUT=50m
export TRAVIS_WORKER_TRAVIS_SITE=org

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}

EOF
}

module "aws_iam_user_s3_com" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-ec2-${var.env}-${var.index}-com"
  s3_bucket_name = "build-trace.travis-ci.com"
}

module "aws_iam_user_s3_org" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-ec2-${var.env}-${var.index}-org"
  s3_bucket_name = "build-trace.travis-ci.org"
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

module "aws_az_1e" {
  source                    = "../modules/aws_workers_az"
  az_group                  = "1e"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1e_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_az_1e2" {
  source                    = "../modules/aws_workers_az"
  az_group                  = "1e2"
  bastion_security_group_id = "${data.terraform_remote_state.vpc.bastion_security_group_1e_id}"
  env                       = "${var.env}"
  index                     = "${var.index}"
  vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
}

module "aws_cyclist_com" {
  source             = "../modules/aws_cyclist"
  cyclist_auth_token = "${random_id.cyclist_token_com.hex}"
  cyclist_version    = "v0.5.0"
  env                = "${var.env}"
  heroku_org         = "${var.aws_heroku_org}"
  index              = "${var.index}"
  site               = "com"
  syslog_address     = "${var.syslog_address_com}"
}

module "aws_cyclist_org" {
  source             = "../modules/aws_cyclist"
  cyclist_auth_token = "${random_id.cyclist_token_org.hex}"
  cyclist_version    = "v0.5.0"
  env                = "${var.env}"
  heroku_org         = "${var.aws_heroku_org}"
  index              = "${var.index}"
  site               = "org"
  syslog_address     = "${var.syslog_address_org}"
}

module "aws_asg_com" {
  source                     = "../modules/aws_asg"
  cyclist_auth_token         = "${random_id.cyclist_token_com.hex}"
  cyclist_url                = "${module.aws_cyclist_com.cyclist_url}"
  docker_storage_dm_basesize = "19G"
  env                        = "${var.env}"
  github_users               = "${var.github_users}"
  index                      = "${var.index}"
  registry_hostname          = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_com_security_group_id}",
    "${module.aws_az_1b2.workers_com_security_group_id}",
    "${module.aws_az_1e.workers_com_security_group_id}",
    "${module.aws_az_1e2.workers_com_security_group_id}",
  ]

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
  worker_asg_scale_out_qty               = 3
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

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_com_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1e2_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1e_id}",
  ]
}

module "aws_asg_com_free" {
  source                     = "../modules/aws_asg_queue"
  cyclist_auth_token         = "${random_id.cyclist_token_com.hex}"
  cyclist_url                = "${module.aws_cyclist_com.cyclist_url}"
  docker_storage_dm_basesize = "19G"
  env                        = "${var.env}"
  github_users               = "${var.github_users}"
  index                      = "${var.index}"
  registry_hostname          = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_com_security_group_id}",
    "${module.aws_az_1b2.workers_com_security_group_id}",
    "${module.aws_az_1e.workers_com_security_group_id}",
    "${module.aws_az_1e2.workers_com_security_group_id}",
  ]

  # TODO: increase worker_asg_max_size to start accepting jobs to the com-free pool

  site                                   = "com"
  syslog_address                         = "${var.syslog_address_com}"
  worker_ami                             = "${var.worker_ami}"
  worker_asg_max_size                    = 0
  worker_asg_min_size                    = 0
  worker_asg_namespace                   = "Travis/com"
  worker_asg_scale_in_threshold          = 120
  worker_asg_scale_in_evaluation_periods = 3
  worker_asg_scale_in_period             = 300
  worker_asg_scale_out_threshold         = 80
  worker_asg_scale_out_qty               = 3
  worker_config                          = "${data.template_file.worker_config_com_free.rendered}"
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
  worker_queue                           = "ec2-free"
  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_com_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1b_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1e2_id}",
    "${data.terraform_remote_state.vpc.workers_com_subnet_1e_id}",
  ]
}

module "aws_asg_org" {
  source                     = "../modules/aws_asg"
  cyclist_auth_token         = "${random_id.cyclist_token_org.hex}"
  cyclist_url                = "${module.aws_cyclist_org.cyclist_url}"
  docker_storage_dm_basesize = "19G"
  env                        = "${var.env}"
  github_users               = "${var.github_users}"
  index                      = "${var.index}"
  registry_hostname          = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_org_security_group_id}",
    "${module.aws_az_1b2.workers_org_security_group_id}",
    "${module.aws_az_1e.workers_org_security_group_id}",
    "${module.aws_az_1e2.workers_org_security_group_id}",
  ]

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

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}",
  ]
}

module "aws_asg_org_canary" {
  source                     = "../modules/aws_asg_canary"
  cyclist_auth_token         = "${random_id.cyclist_token_org.hex}"
  cyclist_url                = "${module.aws_cyclist_org.cyclist_url}"
  docker_storage_dm_basesize = "19G"
  env                        = "${var.env}"
  github_users               = "${var.github_users}"
  index                      = "${var.index}"
  registry_hostname          = "${data.terraform_remote_state.vpc.registry_hostname}"

  security_groups = [
    "${module.aws_az_1b.workers_org_security_group_id}",
    "${module.aws_az_1b2.workers_org_security_group_id}",
    "${module.aws_az_1e.workers_org_security_group_id}",
    "${module.aws_az_1e2.workers_org_security_group_id}",
  ]

  site                        = "org"
  syslog_address              = "${var.syslog_address_org}"
  worker_ami                  = "${var.worker_ami_canary}"
  worker_asg_max_size         = 3
  worker_asg_min_size         = 0
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
  worker_docker_self_image    = "${var.worker_image_canary}"
  worker_instance_type        = "c3.8xlarge"
  worker_queue                = "ec2"

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}",
  ]
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
