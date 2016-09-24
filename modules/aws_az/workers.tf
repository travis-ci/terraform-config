resource "aws_subnet" "workers_com" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.workers_com_subnet}"
  availability_zone = "us-east-${var.az}"
  tags = {
    Name = "workers-com-${var.az}"
  }
}

resource "aws_subnet" "workers_org" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.workers_org_subnet}"
  availability_zone = "us-east-${var.az}"
  tags = {
    Name = "workers-org-${var.az}"
  }
}

resource "aws_route_table" "workers_com" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }
}

resource "aws_route_table" "workers_org" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }
}

resource "aws_route_table_association" "workers_com" {
  subnet_id = "${aws_subnet.workers_com.id}"
  route_table_id = "${aws_route_table.workers_com.id}"
}

resource "aws_route_table_association" "workers_org" {
  subnet_id = "${aws_subnet.workers_org.id}"
  route_table_id = "${aws_route_table.workers_org.id}"
}
