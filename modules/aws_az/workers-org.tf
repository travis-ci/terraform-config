resource "aws_subnet" "workers_org" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.workers_org_subnet}"
  availability_zone = "us-east-${var.az}"
  tags = {
    Name = "${var.env}-workers-org-${var.az}"
  }
}

resource "aws_route_table" "workers_org" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }
}

resource "aws_route_table_association" "workers_org" {
  subnet_id = "${aws_subnet.workers_org.id}"
  route_table_id = "${aws_route_table.workers_org.id}"
}

resource "aws_security_group" "workers_org" {
  name = "${var.env}-workers-org-nat-${var.az}"
  description = "NAT Security Group for Workers VPC"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
