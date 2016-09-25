resource "aws_route53_zone" "az" {
  name = "aws-us-east-${var.az}.travisci.net"

  tags {
    AvailabilityZone = "${var.az}"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.public_subnet}"
  availability_zone = "us-east-${var.az}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-${var.index}-public-${var.az}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "204.236.218.9/32"
    instance_id = "${aws_instance.nat_quay.id}"
  }

  route {
    cidr_block = "184.73.231.61/32"
    instance_id = "${aws_instance.nat_quay.id}"
  }

  route {
    cidr_block = "54.243.33.104/32"
    instance_id = "${aws_instance.nat_quay.id}"
  }

  route {
    cidr_block = "54.243.165.120/32"
    instance_id = "${aws_instance.nat_quay.id}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.gateway_id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}
