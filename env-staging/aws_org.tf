resource "aws_route_table" "workers_org" {
    vpc_id = "${aws_vpc.workers.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_org.id}"
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

resource "aws_eip" "nat_org" {
    instance = "${aws_instance.nat_org.id}"
    vpc = true
    depends_on = ["aws_route_table.workers_org"]
}

resource "aws_security_group" "nat_org" {
    name = "workers-nat-org"
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

resource "aws_instance" "nat_org" {
    ami = "SECRET" # todo
    instance_type = "c3.8xlarge"
    vpc_security_group_ids = ["${aws_security_group.nat_org.id}"]
    subnet_id = "${aws_subnet.workers_org.id}"
    key_name = "travis-shared-key"
    tags = {
        Name = "workers-nat-org-1e"
        site = "org"
    }
    source_dest_check = false
}
