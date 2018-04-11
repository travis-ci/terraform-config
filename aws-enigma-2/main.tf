variable "env" {
  default = "enigma"
}

variable "worker_ami" {
  # tfw 2018-03-08 00-09-18
  default = "ami-07dd1aada92124d1e"
}

variable "syslog_address_org" {}

variable "github_users" {}

variable "index" {
  default = 2
}

variable "rabbitmq_password_org" {}
variable "rabbitmq_username_org" {}

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

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/aws-shared-2.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
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

module "aws_asg_org" {
  source                     = "../modules/aws_asg_fixed"
  docker_storage_dm_basesize = "19G"
  env                        = "${var.env}"
  env_short                  = "${var.env}"
  github_users               = "${var.github_users}"
  index                      = "${var.index}"
  registry_hostname          = "${data.terraform_remote_state.vpc.registry_hostname}"

  // TODO: import these at some point
  security_groups = [
    "sg-902860ea",
    "sg-c62caeb3",
    "sg-9c2860e6",
    "sg-5335b726",
  ]

  site            = "org"
  syslog_address  = "${var.syslog_address_org}"
  worker_ami      = "${var.worker_ami}"
  worker_asg_size = 1

  //worker_asg_namespace        = "Travis/org"
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
  worker_instance_type        = "c3.8xlarge"
  worker_queue                = "enigma"

  worker_subnets = [
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1b_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e2_id}",
    "${data.terraform_remote_state.vpc.workers_org_subnet_1e_id}",
  ]
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
