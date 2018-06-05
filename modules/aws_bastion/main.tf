variable "az" {}
variable "bastion_ami" {}

variable "bastion_instance_type" {
  default = "t2.micro"
}

variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}
variable "env" {}

variable "github_users" {
  default = ""
}

variable "index" {}
variable "public_subnet_id" {}
variable "syslog_address" {}
variable "travisci_net_external_zone_id" {}
variable "vpc_id" {}

resource "aws_security_group" "bastion" {
  name        = "${var.env}-${var.index}-bastion-${var.az}"
  description = "Security Group for bastion server for VPC"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.index}-bastion-${var.az}"
  }
}

data "template_file" "duo_config" {
  template = <<EOF
# Written by cloud-init :heart:
[duo]
ikey = ${var.duo_integration_key}
skey = ${var.duo_secret_key}
host = ${var.duo_api_hostname}
failmode = secure
EOF
}

data "template_file" "bastion_cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    hostname_tmpl  = "bastion-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
    syslog_address = "${var.syslog_address}"
    duo_config     = "${data.template_file.duo_config.rendered}"

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "aws_instance" "bastion" {
  ami           = "${var.bastion_ami}"
  instance_type = "${var.bastion_instance_type}"
  subnet_id     = "${var.public_subnet_id}"

  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
  ]

  tags = {
    Name = "${var.env}-${var.index}-bastion-${var.az}"
  }

  user_data = "${data.template_file.bastion_cloud_config.rendered}"
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}

resource "aws_route53_record" "bastion" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "bastion-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${aws_eip.bastion.public_ip}"]
}

output "eip" {
  value = "${aws_eip.bastion.public_ip}"
}

output "id" {
  value = "${aws_instance.bastion.id}"
}

output "sg_id" {
  value = "${aws_security_group.bastion.id}"
}
