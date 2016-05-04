provider "aws" {}

resource "aws_vpc" "workers" {
    cidr_block = "10.2.0.0/16"
    tags = {
        Name = "workers-staging"
    }
}

resource "aws_internet_gateway" "workers" {
    vpc_id = "${aws_vpc.workers.id}"
}
