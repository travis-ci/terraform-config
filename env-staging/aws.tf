provider "aws" {}

resource "aws_vpc" "workers" {
    cidr_block = "10.2.0.0/16"
    tags = {
        Name = "workers-staging"
    }
}

resource "aws_subnet" "workers_com" {
    vpc_id = "${aws_vpc.workers.id}"
    cidr_block = "10.2.1.0/24"
    availability_zone = "us-east-1e"
    tags = {
        Name = "workers-com"
    }
}

resource "aws_subnet" "workers_org" {
    vpc_id = "${aws_vpc.workers.id}"
    cidr_block = "10.2.2.0/24"
    availability_zone = "us-east-1e"
    tags = {
        Name = "workers-org"
    }
}

# todo figure out
# * aws_eip.nat_com: Failure associating EIP: Gateway.NotAttached: Network vpc-5d27d43a is not attached to any internet gateway
#
#resource "aws_eip" "nat_com" {
#    instance = "${aws_instance.nat_com.id}"
#    vpc = true
#}

resource "aws_security_group" "nat_com" {
    name = "workers-nat"
    description = "NAT Security Group for Workers VPC"
    vpc_id = "${aws_vpc.workers.id}"

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "${aws_subnet.workers_com.cidr_block}",
            "${aws_subnet.workers_org.cidr_block}",
        ]
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "${aws_subnet.workers_com.cidr_block}",
            "${aws_subnet.workers_org.cidr_block}",
        ]
    }

#    ingress {
#        from_port = 22
#        to_port = 22
#        protocol = "tcp"
#        security_groups = ["${aws_security_group.workers_bastion.id}"]
#    }
}

resource "aws_instance" "nat_com" {
    ami = "SECRET" # todo
    instance_type = "c3.8xlarge"
    vpc_security_group_ids = ["${aws_security_group.nat_com.id}"]
    subnet_id = "${aws_subnet.workers_com.id}"
    key_name = "travis-shared-key"
    tags = {
        Name = "workers-nat-com-1e"
        site = "com"
    }
    source_dest_check = false
}
