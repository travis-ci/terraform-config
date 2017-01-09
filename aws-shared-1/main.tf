variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}
variable "env" { default = "shared" }
variable "github_users" {}
variable "index" { default = 1 }
variable "public_subnet_1b_cidr" { default = "10.10.1.0/24" }
variable "public_subnet_1e_cidr" { default = "10.10.4.0/24" }
variable "syslog_address_com" {}
variable "travisci_net_external_zone_id" { default = "Z2RI61YP4UWSIO" }
variable "vpc_cidr" { default = "10.10.0.0/16" }
variable "workers_com_subnet_1b_cidr" { default = "10.10.3.0/24" }
variable "workers_com_subnet_1e_cidr" { default = "10.10.5.0/24" }
variable "workers_org_subnet_1b_cidr" { default = "10.10.2.0/24" }
variable "workers_org_subnet_1e_cidr" { default = "10.10.6.0/24" }

provider "aws" {}

data "aws_ami" "nat" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["137112412989"] # Amazon
}

data "aws_ami" "bastion" {
  most_recent = true
  filter {
    name = "tag:role"
    values = ["bastion"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["self"]
}

data "aws_ami" "docker" {
  most_recent = true
  filter {
    name = "tag:role"
    values = ["worker"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["self"]
}

resource "random_id" "registry_http_secret" {
  byte_length = 16
}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
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
  vpc_id = "${aws_vpc.main.id}"
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

module "aws_az_1b" {
  source = "../modules/aws_az"
  az = "1b"
  bastion_ami = "${data.aws_ami.bastion.id}"
  duo_api_hostname = "${var.duo_api_hostname}"
  duo_integration_key = "${var.duo_integration_key}"
  duo_secret_key = "${var.duo_secret_key}"
  env = "${var.env}"
  gateway_id = "${aws_internet_gateway.gw.id}"
  github_users = "${var.github_users}"
  index = "${var.index}"
  nat_ami = "${data.aws_ami.nat.id}"
  nat_instance_type = "c4.large"
  public_subnet_cidr = "${var.public_subnet_1b_cidr}"
  syslog_address = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpc_id = "${aws_vpc.main.id}"
  workers_com_subnet_cidr = "${var.workers_com_subnet_1b_cidr}"
  workers_org_subnet_cidr = "${var.workers_org_subnet_1b_cidr}"
}

module "aws_az_1e" {
  source = "../modules/aws_az"
  az = "1e"
  bastion_ami = "${data.aws_ami.bastion.id}"
  duo_api_hostname = "${var.duo_api_hostname}"
  duo_integration_key = "${var.duo_integration_key}"
  duo_secret_key = "${var.duo_secret_key}"
  env = "${var.env}"
  gateway_id = "${aws_internet_gateway.gw.id}"
  github_users = "${var.github_users}"
  index = "${var.index}"
  nat_ami = "${data.aws_ami.nat.id}"
  nat_instance_type = "c4.large"
  public_subnet_cidr = "${var.public_subnet_1e_cidr}"
  syslog_address = "${var.syslog_address_com}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpc_id = "${aws_vpc.main.id}"
  workers_com_subnet_cidr = "${var.workers_com_subnet_1e_cidr}"
  workers_org_subnet_cidr = "${var.workers_org_subnet_1e_cidr}"
}

resource "aws_route53_record" "workers_org_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "workers-nat-org-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type = "A"
  ttl = 300
  records = [
    "${module.aws_az_1b.workers_org_nat_eip}",
    "${module.aws_az_1e.workers_org_nat_eip}",
  ]
}

resource "aws_route53_record" "workers_com_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "workers-nat-com-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type = "A"
  ttl = 300
  records = [
    "${module.aws_az_1b.workers_com_nat_eip}",
    "${module.aws_az_1e.workers_com_nat_eip}",
  ]
}

resource "aws_s3_bucket" "registry_images" {
  acl = "public-read"
  bucket = "travis-${var.env}-${var.index}-registry-images"
  region = "us-east-1"
}

resource "aws_iam_user" "registry" {
  name = "registry-${var.env}-${var.index}"
}

resource "aws_iam_access_key" "registry" {
  user = "${aws_iam_user.registry.name}"
}

resource "aws_iam_user_policy" "registry" {
  name = "registry-${var.env}-${var.index}-policy"
  user = "${aws_iam_user.registry.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "${aws_s3_bucket.registry_images.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "${aws_s3_bucket.registry_images.arn}/*"
    }
  ]
}
EOF
}

module "registry_1b" {
  source = "../modules/aws_docker_registry"
  ami = "${data.aws_ami.docker.id}"
  az = "1b"
  env = "${var.env}"
  github_users = "${var.github_users}"
  http_secret = "${random_id.registry_http_secret.hex}"
  index = "${var.index}"
  instance_type = "t2.micro"
  public_subnet_id = "${module.aws_az_1b.public_subnet_id}"
  s3_access_key_id = "${aws_iam_access_key.registry.id}"
  s3_bucket = "${aws_s3_bucket.registry_images.id}"
  s3_secret_access_key = "${aws_iam_access_key.registry.secret}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpc_id = "${aws_vpc.main.id}"
}

module "registry_1e" {
  source = "../modules/aws_docker_registry"
  ami = "${data.aws_ami.docker.id}"
  az = "1e"
  env = "${var.env}"
  github_users = "${var.github_users}"
  http_secret = "${random_id.registry_http_secret.hex}"
  index = "${var.index}"
  instance_type = "t2.micro"
  public_subnet_id = "${module.aws_az_1e.public_subnet_id}"
  s3_access_key_id = "${aws_iam_access_key.registry.id}"
  s3_bucket = "${aws_s3_bucket.registry_images.id}"
  s3_secret_access_key = "${aws_iam_access_key.registry.secret}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "registry_elb" {
  name = "${var.env}-${var.index}-registry-elb"
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "registry" {
  name = "registry-elb-${var.env}-${var.index}"
  subnets = [
    "${module.aws_az_1b.public_subnet_id}",
    "${module.aws_az_1e.public_subnet_id}"
  ]
  security_groups = ["${aws_security_group.registry_elb.id}"]
  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 9
    target = "HTTP:8000/v2/"
    interval = 10
    timeout = 5
  }
  instances = [
    "${module.registry_1b.instance_id}",
    "${module.registry_1e.instance_id}"
  ]
  internal = true
  tags {
    Name = "registry-elb-${var.env}-${var.index}"
  }
}

resource "aws_route53_record" "registry" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "registry-elb-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type = "A"
  alias {
    name = "${aws_elb.registry.dns_name}"
    zone_id = "${aws_elb.registry.zone_id}"
    evaluate_target_health = false
  }
}

resource "null_resource" "outputs_signature" {
  triggers {
    bastion_security_group_1b_id = "${module.aws_az_1b.bastion_sg_id}"
    bastion_security_group_1e_id = "${module.aws_az_1e.bastion_sg_id}"
    gateway_id = "${aws_internet_gateway.gw.id}"
    public_subnet_1b_cidr = "${var.public_subnet_1b_cidr}"
    public_subnet_1e_cidr = "${var.public_subnet_1e_cidr}"
    vpc_id = "${aws_vpc.main.id}"
    workers_com_nat_1b_id = "${module.aws_az_1b.workers_com_nat_id}"
    workers_com_nat_1e_id = "${module.aws_az_1e.workers_com_nat_id}"
    workers_com_subnet_1b_cidr = "${var.workers_com_subnet_1b_cidr}"
    workers_com_subnet_1b_id = "${module.aws_az_1b.workers_com_subnet_id}"
    workers_com_subnet_1e_cidr = "${var.workers_com_subnet_1e_cidr}"
    workers_com_subnet_1e_id = "${module.aws_az_1e.workers_com_subnet_id}"
    workers_org_nat_1b_id= "${module.aws_az_1b.workers_org_nat_id}"
    workers_org_nat_1e_id= "${module.aws_az_1e.workers_org_nat_id}"
    workers_org_subnet_1b_cidr = "${var.workers_org_subnet_1b_cidr}"
    workers_org_subnet_1b_id = "${module.aws_az_1b.workers_org_subnet_id}"
    workers_org_subnet_1e_cidr = "${var.workers_org_subnet_1e_cidr}"
    workers_org_subnet_1e_id = "${module.aws_az_1e.workers_org_subnet_id}"
  }
}

output "bastion_security_group_1b_id" { value = "${module.aws_az_1b.bastion_sg_id}" }
output "bastion_security_group_1e_id" { value = "${module.aws_az_1e.bastion_sg_id}" }
output "gateway_id" { value = "${aws_internet_gateway.gw.id}" }
output "public_subnet_1b_cidr" { value = "${var.public_subnet_1b_cidr}" }
output "public_subnet_1e_cidr" { value = "${var.public_subnet_1e_cidr}" }
output "registry_1b_hostname" { value = "${module.registry_1b.hostname}" }
output "registry_1b_private_ip" { value = "${module.registry_1b.private_ip}" }
output "registry_1e_hostname" { value = "${module.registry_1e.hostname}" }
output "registry_1e_private_ip" { value = "${module.registry_1e.private_ip}" }
output "registry_dns_name" { value = "${aws_route53_record.registry.fqdn}" }
output "vpc_id" { value = "${aws_vpc.main.id}" }
output "workers_com_nat_1b_id" { value = "${module.aws_az_1b.workers_com_nat_id}" }
output "workers_com_nat_1e_id" { value = "${module.aws_az_1e.workers_com_nat_id}" }
output "workers_com_subnet_1b_cidr" { value = "${var.workers_com_subnet_1b_cidr}" }
output "workers_com_subnet_1b_id" { value = "${module.aws_az_1b.workers_com_subnet_id}" }
output "workers_com_subnet_1e_cidr" { value = "${var.workers_com_subnet_1e_cidr}" }
output "workers_com_subnet_1e_id" { value = "${module.aws_az_1e.workers_com_subnet_id}" }
output "workers_org_nat_1b_id" { value = "${module.aws_az_1b.workers_org_nat_id}" }
output "workers_org_nat_1e_id" { value = "${module.aws_az_1e.workers_org_nat_id}" }
output "workers_org_subnet_1b_cidr" { value = "${var.workers_org_subnet_1b_cidr}" }
output "workers_org_subnet_1b_id" { value = "${module.aws_az_1b.workers_org_subnet_id}" }
output "workers_org_subnet_1e_cidr" { value = "${var.workers_org_subnet_1e_cidr}" }
output "workers_org_subnet_1e_id" { value = "${module.aws_az_1e.workers_org_subnet_id}" }
