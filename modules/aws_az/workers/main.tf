variable "az" {}
variable "cidr_block" {}
variable "env" {}
variable "index" {}
variable "nat_ami" {}
variable "nat_instance_type" {}
variable "public_subnet_id" {}
variable "site" {}
variable "vpc_id" {}

resource "aws_security_group" "nat" {
  name = "${var.env}-${var.index}-workers-nat-${var.site}-${var.az}"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "subnet" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.cidr_block}"
  availability_zone = "us-east-${var.az}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-${var.index}-workers-${var.site}-${var.az}"
  }
}

resource "aws_instance" "nat" {
  ami = "${var.nat_ami}"
  instance_type = "${var.nat_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id = "${var.public_subnet_id}"
  source_dest_check = false
  tags = {
    Name = "${var.env}-${var.index}-workers-nat-${var.site}-${var.az}"
  }
}

resource "aws_network_interface" "nat" {
  subnet_id = "${aws_subnet.subnet.id}"
  security_groups = ["${aws_security_group.nat.id}"]
  attachment {
    instance = "${aws_instance.nat.id}"
    device_index = 1
  }
  tags = {
    Name = "${var.env}-${var.index}-workers-nat-private-${var.site}-${var.az}"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = "${aws_network_interface.nat.id}"
  }
  tags = {
    Name = "${var.env}-${var.index}-workers-${var.site}-${var.az}"
  }
}

resource "aws_route_table_association" "rtbassoc" {
  subnet_id = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_eip" "nat" {
  network_interface = "${aws_instance.nat.network_interface_id}"
  vpc = true
  depends_on = ["aws_route_table.rtb"]
}

output "subnet_id" { value = "${aws_subnet.subnet.id}" }
output "nat_id" { value = "${aws_instance.nat.id}" }
output "nat_eip" { value = "${aws_eip.nat.public_ip}" }
