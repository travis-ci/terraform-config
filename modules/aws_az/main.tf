variable "az" {}
variable "az_group" {}
variable "env" {}
variable "gateway_id" {}
variable "index" {}
variable "nat_ami" {}
variable "nat_instance_type" {}
variable "public_subnet_id" {}
variable "travisci_net_external_zone_id" {}
variable "vpc_cidr" {}
variable "vpc_id" {}
variable "workers_com_subnet_cidr" {}
variable "workers_org_subnet_cidr" {}

module "workers_org" {
  source            = "./workers"
  az                = "${var.az}"
  az_group          = "${var.az_group}"
  cidr_block        = "${var.workers_org_subnet_cidr}"
  env               = "${var.env}"
  index             = "${var.index}"
  nat_ami           = "${var.nat_ami}"
  nat_instance_type = "${var.nat_instance_type}"
  public_subnet_id  = "${var.public_subnet_id}"
  site              = "org"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_id            = "${var.vpc_id}"
}

module "workers_com" {
  source            = "./workers"
  az                = "${var.az}"
  az_group          = "${var.az_group}"
  cidr_block        = "${var.workers_com_subnet_cidr}"
  env               = "${var.env}"
  index             = "${var.index}"
  nat_ami           = "${var.nat_ami}"
  nat_instance_type = "${var.nat_instance_type}"
  public_subnet_id  = "${var.public_subnet_id}"
  site              = "com"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_id            = "${var.vpc_id}"
}

resource "aws_route53_record" "workers_org_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-org-${var.env}-${var.index}.aws-us-east-${var.az_group}.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${module.workers_org.nat_eip}"]
}

resource "aws_route53_record" "workers_com_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "workers-nat-com-${var.env}-${var.index}.aws-us-east-${var.az_group}.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${module.workers_com.nat_eip}"]
}

output "workers_com_nat_eip" {
  value = "${module.workers_com.nat_eip}"
}

output "workers_com_nat_id" {
  value = "${module.workers_com.nat_id}"
}

output "workers_com_route_table_id" {
  value = "${module.workers_com.route_table_id}"
}

output "workers_com_subnet_id" {
  value = "${module.workers_com.subnet_id}"
}

output "workers_org_nat_eip" {
  value = "${module.workers_org.nat_eip}"
}

output "workers_org_nat_id" {
  value = "${module.workers_org.nat_id}"
}

output "workers_org_route_table_id" {
  value = "${module.workers_org.route_table_id}"
}

output "workers_org_subnet_id" {
  value = "${module.workers_org.subnet_id}"
}
