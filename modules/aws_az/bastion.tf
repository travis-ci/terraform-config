resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
  depends_on = ["aws_route_table.public"]
}

resource "aws_security_group" "bastion" {
  name = "${var.env}-${var.index}-bastion-${var.az}"
  description = "Security Group for bastion server for Workers VPC"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "bastion_cloud_init" {
  template = "${file("${path.module}/bastion-cloud-init.tpl")}"

  vars {
    bastion_config = "${var.bastion_config}"
    env = "${var.env}"
    index = "${var.index}"
  }
}

resource "aws_instance" "bastion" {
  ami = "${var.bastion_ami}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  subnet_id = "${aws_subnet.public.id}"
  tags = {
    Name = "${var.env}-${var.index}-bastion-${var.az}"
  }
  user_data = "${data.template_file.bastion_cloud_init.rendered}"
}
