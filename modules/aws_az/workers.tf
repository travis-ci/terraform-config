resource "aws_subnet" "workers" {
    vpc_id = "${var.aws_vpc_id}"
    cidr_block = "${var.aws_workers_subnet}"
    availability_zone = "us-east-${var.aws_az}"
    tags = {
        Name = "${var.env_name}-workers-${var.aws_az}"
    }
}

resource "aws_route_table" "workers" {
    vpc_id = "${var.aws_vpc_id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }
}

resource "aws_route_table_association" "workers" {
    subnet_id = "${aws_subnet.workers.id}"
    route_table_id = "${aws_route_table.workers.id}"
}

resource "aws_security_group" "workers" {
    name = "${var.env_name}-workers-nat-${var.aws_az}"
    description = "NAT Security Group for Workers VPC"
    vpc_id = "${var.aws_vpc_id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion.id}"]
    }
}
