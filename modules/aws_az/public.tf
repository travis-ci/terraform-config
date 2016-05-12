resource "aws_subnet" "public" {
    vpc_id = "${var.aws_vpc_id}"
    cidr_block = "${var.aws_public_subnet}"
    availability_zone = "us-east-${var.aws_az}"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.env_name}-public-${var.aws_az}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = "${var.aws_vpc_id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${var.aws_gateway_id}"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public.id}"
    route_table_id = "${aws_route_table.public.id}"
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
    depends_on = ["aws_route_table.workers"]
}

resource "aws_eip" "bastion" {
    instance = "${aws_instance.bastion.id}"
    vpc = true
    depends_on = ["aws_route_table.public"]
}

resource "aws_security_group" "nat" {
    name = "${var.env_name}-public-nat-${var.aws_az}"
    description = "NAT Security Group for Public VPC"
    vpc_id = "${var.aws_vpc_id}"

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "${aws_subnet.public.cidr_block}",
        ]
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "${aws_subnet.public.cidr_block}",
        ]
    }
}

resource "aws_security_group" "bastion" {
    name = "${var.env_name}-bastion-${var.aws_az}"
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
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "nat" {
    ami = "${var.aws_nat_ami}"
    instance_type = "c3.8xlarge"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.public.id}"
    key_name = "travis-shared-key"
    tags = {
        Name = "${var.env_name}-nat-${var.aws_az}"
    }
    source_dest_check = false
}

resource "aws_instance" "bastion" {
    ami = "${var.aws_bastion_ami}"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
    subnet_id = "${aws_subnet.public.id}"
    tags = {
        Name = "${var.env_name}-bastion-${var.aws_az}"
    }
    user_data = "#cloud-config\nhostname: ${var.env_name}-bastion-${var.aws_az}\nfqdn: ${var.env_name}-bastion-${var.aws_az}.travisci.net\nmanage_etc_hosts: true"
}
