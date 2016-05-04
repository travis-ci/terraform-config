resource "aws_route_table" "workers_com" {
    vpc_id = "${aws_vpc.workers.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_com_1e.id}"
    }
}

resource "aws_subnet" "workers_com_1e" {
    vpc_id = "${aws_vpc.workers.id}"
    cidr_block = "10.2.1.0/24"
    availability_zone = "us-east-1e"
    tags = {
        Name = "workers-com"
    }
}

resource "aws_eip" "nat_com_1e" {
    instance = "${aws_instance.nat_com_1e.id}"
    vpc = true
    depends_on = ["aws_route_table.workers_com"]
}

resource "aws_security_group" "nat_com_1e" {
    name = "workers-nat-com"
    description = "NAT Security Group for Workers VPC"
    vpc_id = "${aws_vpc.workers.id}"

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "${aws_subnet.workers_com_1e.cidr_block}",
            "${aws_subnet.workers_org_1e.cidr_block}",
        ]
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = [
            "${aws_subnet.workers_com_1e.cidr_block}",
            "${aws_subnet.workers_org_1e.cidr_block}",
        ]
    }

#    ingress {
#        from_port = 22
#        to_port = 22
#        protocol = "tcp"
#        security_groups = ["${aws_security_group.workers_bastion.id}"]
#    }
}

resource "aws_instance" "nat_com_1e" {
    ami = "SECRET" # todo
    instance_type = "c3.8xlarge"
    vpc_security_group_ids = ["${aws_security_group.nat_com_1e.id}"]
    subnet_id = "${aws_subnet.workers_com_1e.id}"
    key_name = "travis-shared-key"
    tags = {
        Name = "workers-nat-com-1e"
        site = "com"
    }
    source_dest_check = false
}
