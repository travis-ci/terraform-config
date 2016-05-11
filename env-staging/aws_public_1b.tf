resource "aws_subnet" "public_1b" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.2.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.env_name}-public-1b"
    }
}

resource "aws_route_table" "public_1b" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
}

resource "aws_route_table_association" "public_1b" {
    subnet_id = "${aws_subnet.public_1b.id}"
    route_table_id = "${aws_route_table.public_1b.id}"
}

resource "aws_eip" "nat_1b" {
    instance = "${aws_instance.nat_1b.id}"
    vpc = true
    depends_on = ["aws_route_table.workers_1b"]
}

resource "aws_eip" "bastion_1b" {
    instance = "${aws_instance.bastion_1b.id}"
    vpc = true
    depends_on = ["aws_route_table.public_1b"]
}

resource "aws_security_group" "nat_1b" {
    name = "${var.env_name}-public-nat-1b"
    description = "NAT Security Group for Public VPC"
    vpc_id = "${aws_vpc.main.id}"

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "${aws_subnet.public_1b.cidr_block}",
        ]
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "${aws_subnet.public_1b.cidr_block}",
        ]
    }
}

resource "aws_security_group" "bastion_1b" {
    name = "${var.env_name}-bastion-1b"
    description = "Security Group for bastion server for Workers VPC"
    vpc_id = "${aws_vpc.main.id}"

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

resource "aws_instance" "nat_1b" {
    ami = "${var.aws_nat_ami}"
    instance_type = "c3.8xlarge"
    vpc_security_group_ids = ["${aws_security_group.nat_1b.id}"]
    subnet_id = "${aws_subnet.public_1b.id}"
    key_name = "travis-shared-key"
    tags = {
        Name = "${var.env_name}-nat-1b"
    }
    source_dest_check = false
}

resource "aws_instance" "bastion_1b" {
    ami = "${var.aws_bastion_ami}"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.bastion_1b.id}"]
    subnet_id = "${aws_subnet.public_1b.id}"
    tags = {
        Name = "${var.env_name}-bastion-1b"
    }
    user_data = "#cloud-config\nhostname: ${var.env_name}-bastion-1b\nfqdn: ${var.env_name}-bastion-1b.travisci.net\nmanage_etc_hosts: true"
}
