variable "ami" {}
variable "az" { default = "1b" }
variable "data_ebs_volume_size" { default = 5 }
variable "env" {}
variable "github_users" {}
variable "http_secret" {}
variable "images_ebs_volume_size" { default = 100 }
variable "index" {}
variable "instance_type" { default = "m3.xlarge" }
variable "public_subnet_id" {}
variable "travisci_net_external_zone_id" {}
variable "vpc_id" {}
variable "vpc_cidr" {}

resource "aws_security_group" "registry" {
  name = "${var.env}-${var.index}-registry-${var.az}"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["${var.vpc_cidr}"]
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

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"
  vars {
    cloud_init_bash = "${file("${path.module}/cloud-init.bash")}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    hostname_tmpl = "registry-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
    http_secret = "${var.http_secret}"
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-${var.az}"
  size = "${var.data_ebs_volume_size}"
  tags {
    Name = "registry-${var.env}-${var.index}-data-${var.az}"
  }
}

resource "aws_ebs_volume" "images" {
  availability_zone = "us-east-${var.az}"
  size = "${var.images_ebs_volume_size}"
  tags {
    Name = "registry-${var.env}-${var.index}-images-${var.az}"
  }
}

resource "aws_instance" "registry" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.public_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.registry.id}"]
  associate_public_ip_address = false
  tags = {
    Name = "${var.env}-${var.index}-registry-${var.az}"
  }
  user_data = "${data.template_file.cloud_config.rendered}"
}

resource "aws_volume_attachment" "data" {
  device_name = "xvdc"
  force_detach = true
  volume_id = "${aws_ebs_volume.data.id}"
  instance_id = "${aws_instance.registry.id}"
}

resource "aws_volume_attachment" "images" {
  device_name = "xvdb"
  force_detach = true
  volume_id = "${aws_ebs_volume.images.id}"
  instance_id = "${aws_instance.registry.id}"
}

resource "aws_route53_record" "registry" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "registry-${var.env}-${var.index}.aws-us-east-${var.az}.travisci.net"
  type = "A"
  ttl = 300
  records = ["${aws_instance.registry.private_ip}"]
  depends_on = ["aws_instance.registry"]
}

output "hostname" { value = "${aws_route53_record.registry.name}" }
output "instance_id" { value = "${aws_instance.registry.id}" }
output "private_ip" { value = "${aws_instance.registry.private_ip}" }
