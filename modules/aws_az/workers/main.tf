variable "az" {}
variable "az_group" {}
variable "cidr_block" {}
variable "env" {}
variable "index" {}
variable "nat_ami" {}
variable "nat_instance_type" {}
variable "public_subnet_id" {}
variable "site" {}
variable "vpc_cidr" {}
variable "vpc_id" {}

variable "worker_nat_packets_out_threshold" {
  default = 100
}

resource "aws_security_group" "nat" {
  name   = "${var.env}-${var.index}-workers-nat-${var.site}-${var.az_group}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "${var.cidr_block}",
      "${var.vpc_cidr}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.index}-workers-nat-${var.site}-${var.az_group}"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${var.cidr_block}"
  availability_zone       = "us-east-${var.az}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${var.index}-workers-${var.site}-${var.az_group}"
  }
}

resource "aws_instance" "nat" {
  ami                    = "${var.nat_ami}"
  instance_type          = "${var.nat_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id              = "${var.public_subnet_id}"
  source_dest_check      = false

  tags = {
    Name = "${var.env}-${var.index}-workers-nat-${var.site}-${var.az_group}"
    role = "nat"
    site = "${var.site}"
    env  = "${var.env}"
  }

  lifecycle {
    ignore_changes = ["ami"]
  }
}

resource "aws_cloudwatch_metric_alarm" "low_packets_out" {
  alarm_description   = "This metric monitors outbound packets through NAT"
  alarm_name          = "low-packets-out-${aws_instance.nat.id}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkPacketsOut"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.worker_nat_packets_out_threshold}"
  treat_missing_data  = "missing"

  dimensions {
    InstanceId = "${aws_instance.nat.id}"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }

  tags = {
    Name = "${var.env}-${var.index}-workers-${var.site}-${var.az_group}"
  }
}

resource "aws_route_table_association" "rtbassoc" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_eip" "nat" {
  instance   = "${aws_instance.nat.id}"
  vpc        = true
  depends_on = ["aws_route_table.rtb"]
}

output "nat_eip" {
  value = "${aws_eip.nat.public_ip}"
}

output "nat_id" {
  value = "${aws_instance.nat.id}"
}

output "route_table_id" {
  value = "${aws_route_table.rtb.id}"
}

output "subnet_id" {
  value = "${aws_subnet.subnet.id}"
}
