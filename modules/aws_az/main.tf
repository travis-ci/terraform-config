variable "az" {}
variable "bastion_ami" {}
variable "bastion_config" {}
variable "env" {}
variable "index" {}
variable "gateway_id" {}
variable "nat_ami" {}
variable "nat_instance_type" {}
variable "public_subnet_cidr" {}
variable "travisci_net_external_zone_id" {}
variable "vpc_cidr" {}
variable "vpc_id" {}
variable "workers_com_subnet_cidr" {}
variable "workers_org_subnet_cidr" {}

resource "aws_subnet" "public" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.public_subnet_cidr}"
  availability_zone = "us-east-${var.az}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-${var.index}-public-${var.az}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.gateway_id}"
  }
  tags = {
    Name = "${var.env}-${var.index}-public-${var.az}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "bastion" {
  name = "${var.env}-${var.index}-bastion-${var.az}"
  description = "Security Group for bastion server for VPC"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-${var.index}-bastion-${var.az}"
  }
}

data "template_file" "bastion_cloud_init" {
  template = "${file("${path.module}/bastion-cloud-init.tpl")}"
  vars {
    instance_hostname = "bastion-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
    bastion_config = "${var.bastion_config}"
  }
}

resource "aws_instance" "bastion" {
  ami = "${var.bastion_ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public.id}"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
  ]
  tags = {
    Name = "${var.env}-${var.index}-bastion-${var.az}"
  }
  user_data = "${data.template_file.bastion_cloud_init.rendered}"
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
}

resource "aws_route53_record" "bastion" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "bastion-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.bastion.public_ip}"]
}

module "workers_org" {
  source = "./workers"
  az = "${var.az}"
  cidr_block = "${var.workers_org_subnet_cidr}"
  env = "${var.env}"
  index = "${var.index}"
  nat_ami = "${var.nat_ami}"
  nat_instance_type = "${var.nat_instance_type}"
  public_subnet_id = "${aws_subnet.public.id}"
  site = "org"
  vpc_cidr = "${var.vpc_cidr}"
  vpc_id = "${var.vpc_id}"
}

module "workers_com" {
  source = "./workers"
  az = "${var.az}"
  cidr_block = "${var.workers_com_subnet_cidr}"
  env = "${var.env}"
  index = "${var.index}"
  nat_ami = "${var.nat_ami}"
  nat_instance_type = "${var.nat_instance_type}"
  public_subnet_id = "${aws_subnet.public.id}"
  site = "com"
  vpc_cidr = "${var.vpc_cidr}"
  vpc_id = "${var.vpc_id}"
}

resource "aws_route53_record" "workers_org_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "workers-nat-org-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
  type = "A"
  ttl = "300"
  records = ["${module.workers_org.nat_eip}"]
}

resource "aws_route53_record" "workers_com_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "workers-nat-com-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
  type = "A"
  ttl = "300"
  records = ["${module.workers_com.nat_eip}"]
}

output "bastion_eip" { value = "${aws_eip.bastion.public_ip}" }
output "bastion_id" { value = "${aws_instance.bastion.id}" }
output "bastion_sg_id" { value = "${aws_security_group.bastion.id}" }
output "route_table_id" { value = "${aws_route_table.public.id}" }
output "workers_com_nat_eip" { value = "${module.workers_com.nat_eip}" }
output "workers_com_nat_id" { value = "${module.workers_com.nat_id}" }
output "workers_com_subnet_id" { value = "${module.workers_com.subnet_id}" }
output "workers_com_route_table_id" { value = "${module.workers_com.route_table_id}" }
output "workers_org_nat_eip" { value = "${module.workers_org.nat_eip}" }
output "workers_org_nat_id" { value = "${module.workers_org.nat_id}" }
output "workers_org_subnet_id" { value = "${module.workers_org.subnet_id}" }
output "workers_org_route_table_id" { value = "${module.workers_org.route_table_id}" }
