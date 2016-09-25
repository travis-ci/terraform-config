resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc = true
  depends_on = ["aws_route_table.public"]
}

resource "aws_security_group" "nat" {
  name = "${var.env}-${var.index}-public-nat-${var.az}"
  description = "NAT Security Group for Public VPC"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${aws_subnet.public.cidr_block}",
      "${var.workers_org_subnet}",
      "${var.workers_com_subnet}",
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat" {
  ami = "${var.nat_ami}"
  instance_type = "${var.nat_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id = "${aws_subnet.public.id}"
  source_dest_check = false

  tags = {
    Name = "${var.env}-${var.index}-nat-${var.az}"
  }
}

resource "aws_instance" "nat_quay" {
  ami = "${var.nat_ami}"
  instance_type = "${var.nat_quay_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id = "${aws_subnet.public.id}"
  source_dest_check = false

  tags = {
    Name = "${var.env}-${var.index}-nat-quay-${var.az}"
  }
}
