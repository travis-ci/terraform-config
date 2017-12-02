variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}

variable "env" {
  default = "shared"
}

variable "github_users" {}

variable "index" {
  default = 2
}

variable "public_subnet_1b_cidr" {
  default = "10.12.1.0/24"
}

variable "public_subnet_1e_cidr" {
  default = "10.12.4.0/24"
}

variable "syslog_address_com" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "vpc_cidr" {
  default = "10.12.0.0/16"
}

variable "workers_com_subnet_1b_cidr" {
  default = "10.12.3.0/24"
}

variable "workers_com_subnet_1b2_cidr" {
  default = "10.12.12.0/24"
}

variable "workers_com_subnet_1e_cidr" {
  default = "10.12.5.0/24"
}

variable "workers_com_subnet_1e2_cidr" {
  default = "10.12.8.0/24"
}

variable "workers_org_subnet_1b_cidr" {
  default = "10.12.2.0/24"
}

variable "workers_org_subnet_1b2_cidr" {
  default = "10.12.11.0/24"
}

variable "workers_org_subnet_1e_cidr" {
  default = "10.12.6.0/24"
}

variable "workers_org_subnet_1e2_cidr" {
  default = "10.12.9.0/24"
}

terraform {
  backend "s3" {
    bucket  = "travis-terraform-state"
    key     = "terraform-config/aws-shared-2.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
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

variable "registry_ami" {
  # tfw 2017-11-07 01-42-17
  default = "ami-0e823274"
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

resource "aws_subnet" "public_1b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_subnet_1b_cidr}"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${var.index}-public-1b"
  }
}

resource "aws_route_table" "public_1b" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "${var.env}-${var.index}-public-1b"
  }
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = "${aws_subnet.public_1b.id}"
  route_table_id = "${aws_route_table.public_1b.id}"
}

resource "aws_subnet" "public_1e" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_subnet_1e_cidr}"
  availability_zone       = "us-east-1e"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${var.index}-public-1e"
  }
}

resource "aws_route_table" "public_1e" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "${var.env}-${var.index}-public-1e"
  }
}

resource "aws_route_table_association" "public_1e" {
  subnet_id      = "${aws_subnet.public_1e.id}"
  route_table_id = "${aws_route_table.public_1e.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [
    "${aws_route_table.public_1b.id}",
    "${aws_route_table.public_1e.id}",
    "${module.aws_az_1b.workers_com_route_table_id}",
    "${module.aws_az_1b.workers_org_route_table_id}",
    "${module.aws_az_1b2.workers_com_route_table_id}",
    "${module.aws_az_1b2.workers_org_route_table_id}",
    "${module.aws_az_1e.workers_com_route_table_id}",
    "${module.aws_az_1e.workers_org_route_table_id}",
    "${module.aws_az_1e2.workers_com_route_table_id}",
    "${module.aws_az_1e2.workers_org_route_table_id}",
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

module "aws_bastion_1b" {
  source                        = "../modules/aws_bastion"
  az                            = "1b"
  bastion_ami                   = "${data.aws_ami.bastion.id}"
  bastion_instance_type         = "t2.nano"
  duo_api_hostname              = "${var.duo_api_hostname}"
  duo_integration_key           = "${var.duo_integration_key}"
  duo_secret_key                = "${var.duo_secret_key}"
  env                           = "${var.env}"
  github_users                  = "${var.github_users}"
  index                         = "${var.index}"
  public_subnet_id              = "${aws_subnet.public_1b.id}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_id                        = "${aws_vpc.main.id}"
}

module "aws_bastion_1e" {
  source                        = "../modules/aws_bastion"
  az                            = "1e"
  bastion_ami                   = "${data.aws_ami.bastion.id}"
  bastion_instance_type         = "t2.nano"
  duo_api_hostname              = "${var.duo_api_hostname}"
  duo_integration_key           = "${var.duo_integration_key}"
  duo_secret_key                = "${var.duo_secret_key}"
  env                           = "${var.env}"
  github_users                  = "${var.github_users}"
  index                         = "${var.index}"
  public_subnet_id              = "${aws_subnet.public_1e.id}"
  syslog_address                = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_id                        = "${aws_vpc.main.id}"
}

module "aws_az_1b" {
  source                        = "../modules/aws_az"
  az                            = "1b"
  az_group                      = "1b"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  index                         = "${var.index}"
  nat_ami                       = "${data.aws_ami.nat.id}"
  nat_instance_type             = "c3.8xlarge"
  public_subnet_id              = "${aws_subnet.public_1b.id}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
  workers_com_subnet_cidr       = "${var.workers_com_subnet_1b_cidr}"
  workers_org_subnet_cidr       = "${var.workers_org_subnet_1b_cidr}"
}

module "aws_az_1b2" {
  source                        = "../modules/aws_az"
  az                            = "1b"
  az_group                      = "1b2"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  index                         = "${var.index}"
  nat_ami                       = "${data.aws_ami.nat.id}"
  nat_instance_type             = "c3.8xlarge"
  public_subnet_id              = "${aws_subnet.public_1b.id}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
  workers_com_subnet_cidr       = "${var.workers_com_subnet_1b2_cidr}"
  workers_org_subnet_cidr       = "${var.workers_org_subnet_1b2_cidr}"
}

module "aws_az_1e" {
  source                        = "../modules/aws_az"
  az                            = "1e"
  az_group                      = "1e"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  index                         = "${var.index}"
  nat_ami                       = "${data.aws_ami.nat.id}"
  nat_instance_type             = "c3.8xlarge"
  public_subnet_id              = "${aws_subnet.public_1e.id}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
  workers_com_subnet_cidr       = "${var.workers_com_subnet_1e_cidr}"
  workers_org_subnet_cidr       = "${var.workers_org_subnet_1e_cidr}"
}

module "aws_az_1e2" {
  source                        = "../modules/aws_az"
  az                            = "1e"
  az_group                      = "1e2"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  index                         = "${var.index}"
  nat_ami                       = "${data.aws_ami.nat.id}"
  nat_instance_type             = "c3.8xlarge"
  public_subnet_id              = "${aws_subnet.public_1e.id}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
  workers_com_subnet_cidr       = "${var.workers_com_subnet_1e2_cidr}"
  workers_org_subnet_cidr       = "${var.workers_org_subnet_1e2_cidr}"
}

resource "aws_route53_record" "workers_org_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-org-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${module.aws_az_1b.workers_org_nat_eip}",
    "${module.aws_az_1b2.workers_org_nat_eip}",
    "${module.aws_az_1e.workers_org_nat_eip}",
    "${module.aws_az_1e2.workers_org_nat_eip}",
  ]
}

resource "aws_route53_record" "workers_com_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-com-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${module.aws_az_1b.workers_com_nat_eip}",
    "${module.aws_az_1b2.workers_com_nat_eip}",
    "${module.aws_az_1e.workers_com_nat_eip}",
    "${module.aws_az_1e2.workers_com_nat_eip}",
  ]
}

module "registry" {
  source                        = "../modules/aws_docker_registry"
  ami                           = "${var.registry_ami}"
  env                           = "${var.env}"
  gateway_id                    = "${aws_internet_gateway.gw.id}"
  github_users                  = "${var.github_users}"
  http_secret                   = "${random_id.registry_http_secret.hex}"
  index                         = "${var.index}"
  instance_type                 = "c4.xlarge"
  subnets                       = ["${aws_subnet.public_1b.id}", "${aws_subnet.public_1e.id}"]
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr                      = "${var.vpc_cidr}"
  vpc_id                        = "${aws_vpc.main.id}"
}

resource "null_resource" "public_ip_addresses_json" {
  triggers {
    workers_com_nat_id = "${aws_route53_record.workers_com_nat.id}"
    workers_org_nat_id = "${aws_route53_record.workers_org_nat.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/format-public-ip-addresses \
    ${aws_route53_record.workers_com_nat.fqdn} \
    ${aws_route53_record.workers_org_nat.fqdn} \
    >${path.module}/generated-public-ip-addresses.json
EOF
  }
}

resource "null_resource" "outputs_signature" {
  triggers {
    bastion_security_group_1b_id = "${module.aws_bastion_1b.sg_id}"
    bastion_security_group_1e_id = "${module.aws_bastion_1e.sg_id}"
    gateway_id                   = "${aws_internet_gateway.gw.id}"
    public_subnet_1b_id          = "${aws_subnet.public_1b.id}"
    public_subnet_1e_id          = "${aws_subnet.public_1e.id}"
    registry_hostname            = "${module.registry.hostname}"
    vpc_id                       = "${aws_vpc.main.id}"
    workers_com_nat_1b2_id       = "${module.aws_az_1b2.workers_com_nat_id}"
    workers_com_nat_1b_id        = "${module.aws_az_1b.workers_com_nat_id}"
    workers_com_nat_1e2_id       = "${module.aws_az_1e2.workers_com_nat_id}"
    workers_com_nat_1e_id        = "${module.aws_az_1e.workers_com_nat_id}"
    workers_com_subnet_1b2_cidr  = "${var.workers_com_subnet_1b2_cidr}"
    workers_com_subnet_1b2_id    = "${module.aws_az_1b2.workers_com_subnet_id}"
    workers_com_subnet_1b_cidr   = "${var.workers_com_subnet_1b_cidr}"
    workers_com_subnet_1b_id     = "${module.aws_az_1b.workers_com_subnet_id}"
    workers_com_subnet_1e2_cidr  = "${var.workers_com_subnet_1e2_cidr}"
    workers_com_subnet_1e2_id    = "${module.aws_az_1e2.workers_com_subnet_id}"
    workers_com_subnet_1e_cidr   = "${var.workers_com_subnet_1e_cidr}"
    workers_com_subnet_1e_id     = "${module.aws_az_1e.workers_com_subnet_id}"
    workers_org_nat_1b2_id       = "${module.aws_az_1b2.workers_org_nat_id}"
    workers_org_nat_1b_id        = "${module.aws_az_1b.workers_org_nat_id}"
    workers_org_nat_1e2_id       = "${module.aws_az_1e2.workers_org_nat_id}"
    workers_org_nat_1e_id        = "${module.aws_az_1e.workers_org_nat_id}"
    workers_org_subnet_1b2_cidr  = "${var.workers_org_subnet_1b2_cidr}"
    workers_org_subnet_1b2_id    = "${module.aws_az_1b2.workers_org_subnet_id}"
    workers_org_subnet_1b_cidr   = "${var.workers_org_subnet_1b_cidr}"
    workers_org_subnet_1b_id     = "${module.aws_az_1b.workers_org_subnet_id}"
    workers_org_subnet_1e2_cidr  = "${var.workers_org_subnet_1e2_cidr}"
    workers_org_subnet_1e2_id    = "${module.aws_az_1e2.workers_org_subnet_id}"
    workers_org_subnet_1e_cidr   = "${var.workers_org_subnet_1e_cidr}"
    workers_org_subnet_1e_id     = "${module.aws_az_1e.workers_org_subnet_id}"
  }
}

output "bastion_security_group_1b_id" {
  value = "${module.aws_bastion_1b.sg_id}"
}

output "bastion_security_group_1e_id" {
  value = "${module.aws_bastion_1e.sg_id}"
}

output "gateway_id" {
  value = "${aws_internet_gateway.gw.id}"
}

output "registry_hostname" {
  value = "${module.registry.hostname}"
}

output "public_subnet_1b_cidr" {
  value = "${var.public_subnet_1b_cidr}"
}

output "public_subnet_1e_cidr" {
  value = "${var.public_subnet_1e_cidr}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "workers_com_nat_1b_id" {
  value = "${module.aws_az_1b.workers_com_nat_id}"
}

output "workers_com_nat_1b2_id" {
  value = "${module.aws_az_1b2.workers_com_nat_id}"
}

output "workers_com_nat_1e_id" {
  value = "${module.aws_az_1e.workers_com_nat_id}"
}

output "workers_com_nat_1e2_id" {
  value = "${module.aws_az_1e2.workers_com_nat_id}"
}

output "workers_com_subnet_1b_cidr" {
  value = "${var.workers_com_subnet_1b_cidr}"
}

output "workers_com_subnet_1b_id" {
  value = "${module.aws_az_1b.workers_com_subnet_id}"
}

output "workers_com_subnet_1b2_cidr" {
  value = "${var.workers_com_subnet_1b2_cidr}"
}

output "workers_com_subnet_1b2_id" {
  value = "${module.aws_az_1b2.workers_com_subnet_id}"
}

output "workers_com_subnet_1e_cidr" {
  value = "${var.workers_com_subnet_1e_cidr}"
}

output "workers_com_subnet_1e_id" {
  value = "${module.aws_az_1e.workers_com_subnet_id}"
}

output "workers_com_subnet_1e2_cidr" {
  value = "${var.workers_com_subnet_1e2_cidr}"
}

output "workers_com_subnet_1e2_id" {
  value = "${module.aws_az_1e2.workers_com_subnet_id}"
}

output "workers_org_nat_1b_id" {
  value = "${module.aws_az_1b.workers_org_nat_id}"
}

output "workers_org_nat_1b2_id" {
  value = "${module.aws_az_1b2.workers_org_nat_id}"
}

output "workers_org_nat_1e_id" {
  value = "${module.aws_az_1e.workers_org_nat_id}"
}

output "workers_org_nat_1e2_id" {
  value = "${module.aws_az_1e2.workers_org_nat_id}"
}

output "workers_org_subnet_1b_cidr" {
  value = "${var.workers_org_subnet_1b_cidr}"
}

output "workers_org_subnet_1b_id" {
  value = "${module.aws_az_1b.workers_org_subnet_id}"
}

output "workers_org_subnet_1b2_cidr" {
  value = "${var.workers_org_subnet_1b2_cidr}"
}

output "workers_org_subnet_1b2_id" {
  value = "${module.aws_az_1b2.workers_org_subnet_id}"
}

output "workers_org_subnet_1e_cidr" {
  value = "${var.workers_org_subnet_1e_cidr}"
}

output "workers_org_subnet_1e_id" {
  value = "${module.aws_az_1e.workers_org_subnet_id}"
}

output "workers_org_subnet_1e2_cidr" {
  value = "${var.workers_org_subnet_1e2_cidr}"
}

output "workers_org_subnet_1e2_id" {
  value = "${module.aws_az_1e2.workers_org_subnet_id}"
}
