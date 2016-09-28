variable "az" {}
variable "bastion_security_group_id" {}
variable "env" {}
variable "index" {}
variable "vpc_id" {}

resource "aws_security_group" "workers_com" {
  name = "${var.env}-${var.index}-workers-com-nat-${var.az}"
  description = "NAT Security Group for Workers VPC"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${var.bastion_security_group_id}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "workers_org" {
  name = "${var.env}-${var.index}-workers-org-nat-${var.az}"
  description = "NAT Security Group for Workers VPC"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${var.bastion_security_group_id}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "workers_com_security_group_id" { value = "${aws_security_group.workers_com.id}" }
output "workers_org_security_group_id" { value = "${aws_security_group.workers_org.id}" }
