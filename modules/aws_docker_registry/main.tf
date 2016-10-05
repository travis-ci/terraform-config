variable "ami" {}
variable "az" { default = "1b" }
variable "env" {}
variable "github_users" {}
variable "index" {}
variable "instance_type" { default = "m3.xlarge" }
variable "letsencrypt_email" { default = "infrastructure+team-blue@travis-ci.org" }
variable "public_subnet_cidr" {}
variable "public_subnet_id" {}
variable "travisci_net_external_zone_id" {}
variable "vpc_id" {}

resource "random_id" "worker_auth" {
  byte_length = 32
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/cloud-init.tpl")}"
  vars {
    github_users = "${var.github_users}"
    instance_hostname = "registry-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
    letsencrypt_email = "${var.letsencrypt_email}"
    worker_auth = "${random_id.worker_auth.hex}"
  }
}

resource "aws_security_group" "registry" {
  name = "${var.env}-${var.index}-registry-${var.az}"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-${var.index}-registry-${var.az}"
  }
}

resource "aws_instance" "registry" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.public_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.registry.id}"]
  tags = {
    Name = "${var.env}-${var.index}-registry-${var.az}"
  }
  user_data = "${data.template_file.cloud_init.rendered}"
}

resource "aws_eip" "registry" {
  instance = "${aws_instance.registry.id}"
  vpc = true
}

resource "aws_route53_record" "registry" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "registry-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
  type = "A"
  ttl = 300
  records = ["${aws_eip.registry.public_ip}"]
  depends_on = ["aws_eip.registry"]
}

output "worker_auth" { value = "${random_id.worker_auth.hex}" }
output "hostname" { value = "${aws_route53_record.registry.name}" }
output "private_ip" { value = "${aws_instance.registry.private_ip}" }
