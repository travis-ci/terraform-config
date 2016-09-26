variable "bastion_ami" { default = "ami-53d4a344" }
variable "env" { default = "shared" }
variable "index" { default = "1" }
variable "nat_ami" { default = "ami-12c5b205" }
variable "public_subnet_1b" { default = "10.10.1.0/24" }
variable "public_subnet_1e" { default = "10.10.4.0/24" }
variable "vpc_cidr" { default = "10.10.0.0/16" }
variable "workers_com_subnet_1b" { default = "10.10.3.0/24" }
variable "workers_com_subnet_1e" { default = "10.10.5.0/24" }
variable "workers_org_subnet_1b" { default = "10.10.2.0/24" }
variable "workers_org_subnet_1e" { default = "10.10.6.0/24" }

provider "aws" {}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_main_route_table_association" "rtbassoc" {
  vpc_id = "${aws_vpc.main.id}"
  route_table_id = "${aws_route_table.public.id}"
  depends_on = ["aws_route_table.public"]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "nat_quay" {
  name = "${var.env}-${var.index}-nat-quay"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat_quay" {
  ami = "${var.nat_ami}"
  instance_type = "c3.2xlarge"
  source_dest_check = false
  subnet_id = "${module.aws_az_1b.public_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.nat_quay.id}"]
  tags = {
    Name = "${var.env}-${var.index}-nat-quay"
  }
}

module "aws_az_1b" {
  source = "../modules/aws_az"

  az = "1b"
  bastion_ami = "${var.bastion_ami}"
  bastion_config = "${file("${path.module}/config/bastion-env")}"
  env = "${var.env}"
  gateway_id = "${aws_internet_gateway.gw.id}"
  index = "${var.index}"
  nat_ami = "${var.nat_ami}"
  nat_instance_type = "c3.8xlarge"
  public_subnet = "${var.public_subnet_1b}"
  public_route_table_id = "${aws_route_table.public.id}"
  vpc_id = "${aws_vpc.main.id}"
  workers_com_subnet = "${var.workers_com_subnet_1b}"
  workers_org_subnet = "${var.workers_org_subnet_1b}"
}

module "aws_az_1e" {
  source = "../modules/aws_az"

  az = "1e"
  bastion_ami = "${var.bastion_ami}"
  bastion_config = "${file("${path.module}/config/bastion-env")}"
  env = "${var.env}"
  gateway_id = "${aws_internet_gateway.gw.id}"
  index = "${var.index}"
  nat_ami = "${var.nat_ami}"
  nat_instance_type = "c3.8xlarge"
  public_subnet = "${var.public_subnet_1e}"
  public_route_table_id = "${aws_route_table.public.id}"
  vpc_id = "${aws_vpc.main.id}"
  workers_com_subnet = "${var.workers_com_subnet_1e}"
  workers_org_subnet = "${var.workers_org_subnet_1e}"
}

resource "null_resource" "outputs_signature" {
  triggers {
    bastion_security_group_id_1b = "${module.aws_az_1b.bastion_sg_id}"
    bastion_security_group_id_1e = "${module.aws_az_1e.bastion_sg_id}"
    gateway_id = "${aws_internet_gateway.gw.id}"
    nat_id_1b = "${module.aws_az_1b.nat_id}"
    nat_id_1e = "${module.aws_az_1e.nat_id}"
    public_subnet_1b = "${module.aws_az_1b.public_subnet}"
    public_subnet_1e = "${module.aws_az_1e.public_subnet}"
    vpc_id = "${aws_vpc.main.id}"
    workers_com_subnet_1b = "${var.workers_com_subnet_1b}"
    workers_com_subnet_1b_id = "${module.aws_az_1b.workers_com_subnet_id}"
    workers_com_subnet_1e = "${var.workers_com_subnet_1e}"
    workers_com_subnet_1e_id = "${module.aws_az_1e.workers_com_subnet_id}"
    workers_org_subnet_1b = "${var.workers_org_subnet_1b}"
    workers_org_subnet_1b_id = "${module.aws_az_1b.workers_org_subnet_id}"
    workers_org_subnet_1e = "${var.workers_org_subnet_1e}"
    workers_org_subnet_1e_id = "${module.aws_az_1e.workers_org_subnet_id}"
  }
}

output "bastion_security_group_id_1b" { value = "${module.aws_az_1b.bastion_sg_id}" }
output "bastion_security_group_id_1e" { value = "${module.aws_az_1e.bastion_sg_id}" }
output "gateway_id" { value = "${aws_internet_gateway.gw.id}" }
output "nat_id_1b" { value = "${module.aws_az_1b.nat_id}" }
output "nat_id_1e" { value = "${module.aws_az_1e.nat_id}" }
output "public_subnet_1b" { value = "${module.aws_az_1b.public_subnet}" }
output "public_subnet_1e" { value = "${module.aws_az_1e.public_subnet}" }
output "vpc_id" { value = "${aws_vpc.main.id}" }
output "workers_com_subnet_1b" { value = "${var.workers_com_subnet_1b}" }
output "workers_com_subnet_1b_id" { value = "${module.aws_az_1b.workers_com_subnet_id}" }
output "workers_com_subnet_1e" { value = "${var.workers_com_subnet_1e}" }
output "workers_com_subnet_1e_id" { value = "${module.aws_az_1e.workers_com_subnet_id}" }
output "workers_org_subnet_1b" { value = "${var.workers_org_subnet_1b}" }
output "workers_org_subnet_1b_id" { value = "${module.aws_az_1b.workers_org_subnet_id}" }
output "workers_org_subnet_1e" { value = "${var.workers_org_subnet_1e}" }
output "workers_org_subnet_1e_id" { value = "${module.aws_az_1e.workers_org_subnet_id}" }
