provider "aws" {}

resource "aws_vpc" "main" {
  cidr_block = "10.2.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env}-main-${var.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}
