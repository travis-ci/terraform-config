variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}

variable "env" {
  default = "shared"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "packer_build_subnet_cidr" {
  default = "10.10.99.0/24"
}

variable "packer_build_repo" {
  default = "travis-infrastructure/packer-build"
}

variable "public_subnet_1b_cidr" {
  default = "10.10.1.0/24"
}

variable "public_subnet_1e_cidr" {
  default = "10.10.4.0/24"
}

variable "syslog_address_com" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "workers_com_subnet_1b_cidr" {
  default = "10.10.3.0/24"
}

variable "workers_com_subnet_1e_cidr" {
  default = "10.10.5.0/24"
}

variable "workers_org_subnet_1b_cidr" {
  default = "10.10.2.0/24"
}

variable "workers_org_subnet_1e_cidr" {
  default = "10.10.6.0/24"
}

provider "aws" {}

data "aws_ami" "nat" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "tag:role"
    values = ["bastion"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

data "aws_ami" "docker" {
  most_recent = true

  filter {
    name   = "tag:role"
    values = ["worker"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

resource "random_id" "registry_http_secret" {
  byte_length = 16
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-${var.index}"
    team = "blue"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.env}-${var.index}-gw"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [
    "${module.aws_az_1b.route_table_id}",
    "${module.aws_az_1b.workers_com_route_table_id}",
    "${module.aws_az_1b.workers_org_route_table_id}",
    "${module.aws_az_1e.route_table_id}",
    "${module.aws_az_1e.workers_com_route_table_id}",
    "${module.aws_az_1e.workers_org_route_table_id}",
  ]

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_subnet" "packer_build" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.packer_build_subnet_cidr}"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.env}-${var.index}-packer-build-1a"
  }
}

resource "aws_route_table" "packer_build" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "${var.env}-${var.index}-packer-build-1a"
  }
}

resource "aws_route_table_association" "packer_build" {
  subnet_id      = "${aws_subnet.packer_build.id}"
  route_table_id = "${aws_route_table.packer_build.id}"
}

module "aws_az_1b" {
  source                        = "../modules/aws_az"
  az                            = "1b"
  bastion_ami                   = "${data.aws_ami.bastion.id}"
  bastion_instance_type         = "t2.nano"
  duo_api_hostname              = "${var.duo_api_hostname}"
  duo_integration_key           = "${var.duo_integration_key}"
  duo_secret_key                = "${var.duo_secret_key}"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  github_users                  = "${var.github_users}"
  index                         = "${var.index}"
  nat_ami                       = "${data.aws_ami.nat.id}"
  nat_instance_type             = "t2.small"
  public_subnet_cidr            = "${var.public_subnet_1b_cidr}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
  workers_com_subnet_cidr       = "${var.workers_com_subnet_1b_cidr}"
  workers_org_subnet_cidr       = "${var.workers_org_subnet_1b_cidr}"
}

module "aws_az_1e" {
  source                        = "../modules/aws_az"
  az                            = "1e"
  bastion_ami                   = "${data.aws_ami.bastion.id}"
  bastion_instance_type         = "t2.nano"
  duo_api_hostname              = "${var.duo_api_hostname}"
  duo_integration_key           = "${var.duo_integration_key}"
  duo_secret_key                = "${var.duo_secret_key}"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  github_users                  = "${var.github_users}"
  index                         = "${var.index}"
  nat_ami                       = "${data.aws_ami.nat.id}"
  nat_instance_type             = "t2.small"
  public_subnet_cidr            = "${var.public_subnet_1e_cidr}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
  workers_com_subnet_cidr       = "${var.workers_com_subnet_1e_cidr}"
  workers_org_subnet_cidr       = "${var.workers_org_subnet_1e_cidr}"
}

resource "aws_route53_record" "workers_org_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-org-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${module.aws_az_1b.workers_org_nat_eip}",
    "${module.aws_az_1e.workers_org_nat_eip}",
  ]
}

resource "aws_route53_record" "workers_com_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-com-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${module.aws_az_1b.workers_com_nat_eip}",
    "${module.aws_az_1e.workers_com_nat_eip}",
  ]
}

module "registry" {
  source                        = "../modules/aws_docker_registry"
  ami                           = "${data.aws_ami.docker.id}"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  github_users                  = "${var.github_users}"
  http_secret                   = "${random_id.registry_http_secret.hex}"
  index                         = "${var.index}"
  instance_type                 = "t2.micro"
  subnets                       = ["${module.aws_az_1b.public_subnet_id}", "${module.aws_az_1e.public_subnet_id}"]
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
}

resource "null_resource" "outputs_signature" {
  triggers {
    bastion_security_group_1b_id = "${module.aws_az_1b.bastion_sg_id}"
    bastion_security_group_1e_id = "${module.aws_az_1e.bastion_sg_id}"
    gateway_id                   = "${aws_internet_gateway.gw.id}"
    packer_build_subnet_cidr     = "${var.packer_build_subnet_cidr}"
    packer_build_subnet_id       = "${aws_subnet.packer_build.id}"
    public_subnet_1b_cidr        = "${var.public_subnet_1b_cidr}"
    public_subnet_1e_cidr        = "${var.public_subnet_1e_cidr}"
    registry_hostname            = "${module.registry.hostname}"
    vpc_id                       = "${aws_vpc.main.id}"
    workers_com_nat_1b_id        = "${module.aws_az_1b.workers_com_nat_id}"
    workers_com_nat_1e_id        = "${module.aws_az_1e.workers_com_nat_id}"
    workers_com_subnet_1b_cidr   = "${var.workers_com_subnet_1b_cidr}"
    workers_com_subnet_1b_id     = "${module.aws_az_1b.workers_com_subnet_id}"
    workers_com_subnet_1e_cidr   = "${var.workers_com_subnet_1e_cidr}"
    workers_com_subnet_1e_id     = "${module.aws_az_1e.workers_com_subnet_id}"
    workers_org_nat_1b_id        = "${module.aws_az_1b.workers_org_nat_id}"
    workers_org_nat_1e_id        = "${module.aws_az_1e.workers_org_nat_id}"
    workers_org_subnet_1b_cidr   = "${var.workers_org_subnet_1b_cidr}"
    workers_org_subnet_1b_id     = "${module.aws_az_1b.workers_org_subnet_id}"
    workers_org_subnet_1e_cidr   = "${var.workers_org_subnet_1e_cidr}"
    workers_org_subnet_1e_id     = "${module.aws_az_1e.workers_org_subnet_id}"
  }

  provisioner "local-exec" {
    command = <<EOF
travis env set -r ${var.packer_build_repo} TRAVIS_VPC_ID ${aws_vpc.main.id};
travis env set -r ${var.packer_build_repo} TRAVIS_SUBNET_ID ${aws_subnet.packer_build.id};
EOF
  }
}

output "bastion_security_group_1b_id" {
  value = "${module.aws_az_1b.bastion_sg_id}"
}

output "bastion_security_group_1e_id" {
  value = "${module.aws_az_1e.bastion_sg_id}"
}

output "gateway_id" {
  value = "${aws_internet_gateway.gw.id}"
}

output "packer_build_subnet_cidr" {
  value = "${var.packer_build_subnet_cidr}"
}

output "packer_build_subnet_id" {
  value = "${aws_subnet.packer_build.id}"
}

output "public_subnet_1b_cidr" {
  value = "${var.public_subnet_1b_cidr}"
}

output "public_subnet_1e_cidr" {
  value = "${var.public_subnet_1e_cidr}"
}

output "registry_hostname" {
  value = "${module.registry.hostname}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "workers_com_nat_1b_id" {
  value = "${module.aws_az_1b.workers_com_nat_id}"
}

output "workers_com_nat_1e_id" {
  value = "${module.aws_az_1e.workers_com_nat_id}"
}

output "workers_com_subnet_1b_cidr" {
  value = "${var.workers_com_subnet_1b_cidr}"
}

output "workers_com_subnet_1b_id" {
  value = "${module.aws_az_1b.workers_com_subnet_id}"
}

output "workers_com_subnet_1e_cidr" {
  value = "${var.workers_com_subnet_1e_cidr}"
}

output "workers_com_subnet_1e_id" {
  value = "${module.aws_az_1e.workers_com_subnet_id}"
}

output "workers_org_nat_1b_id" {
  value = "${module.aws_az_1b.workers_org_nat_id}"
}

output "workers_org_nat_1e_id" {
  value = "${module.aws_az_1e.workers_org_nat_id}"
}

output "workers_org_subnet_1b_cidr" {
  value = "${var.workers_org_subnet_1b_cidr}"
}

output "workers_org_subnet_1b_id" {
  value = "${module.aws_az_1b.workers_org_subnet_id}"
}

output "workers_org_subnet_1e_cidr" {
  value = "${var.workers_org_subnet_1e_cidr}"
}

output "workers_org_subnet_1e_id" {
  value = "${module.aws_az_1e.workers_org_subnet_id}"
}
