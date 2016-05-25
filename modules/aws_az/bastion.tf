resource "aws_eip" "bastion" {
    instance = "${aws_instance.bastion.id}"
    vpc = true
    depends_on = ["aws_route_table.public"]
}

resource "aws_security_group" "bastion" {
    name = "${var.env}-bastion-${var.aws_az}"
    description = "Security Group for bastion server for Workers VPC"
    vpc_id = "${var.aws_vpc_id}"

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

resource "aws_instance" "bastion" {
    ami = "${var.aws_bastion_ami}"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
    subnet_id = "${aws_subnet.public.id}"
    tags = {
        Name = "${var.env}-bastion-${var.aws_az}"
    }
    user_data = <<EOF
#cloud-config
hostname: ${var.env}-bastion-${var.aws_az}
fqdn: ${var.env}-bastion-${var.aws_az}.travisci.net
manage_etc_hosts: true
EOF
}
