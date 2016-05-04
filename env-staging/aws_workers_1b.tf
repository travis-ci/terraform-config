resource "aws_subnet" "workers_1b" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.2.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "${var.env_name}-workers-1b"
    }
}

resource "aws_route_table" "workers_1b" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_1b.id}"
    }
}

resource "aws_security_group" "workers_1b" {
    name = "${var.env_name}-workers-nat-1b"
    description = "NAT Security Group for Workers VPC"
    vpc_id = "${aws_vpc.main.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion_1b.id}"]
    }
}
