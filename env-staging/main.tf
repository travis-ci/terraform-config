module "aws_az_1b" {
    source = "../modules/aws_az"

    env_name = "${var.env_name}"
    aws_az = "1b"
    aws_public_subnet = "10.2.1.0/24"
    aws_workers_subnet = "10.2.2.0/24"
    aws_vpc_id = "${aws_vpc.main.id}"
    aws_gateway_id = "${aws_internet_gateway.gw.id}"

    aws_bastion_ami = "${var.aws_bastion_ami}"
    aws_worker_ami = "${var.aws_worker_ami}"
    aws_nat_ami = "${var.aws_nat_ami}"
}

module "aws_az_1e" {
    source = "../modules/aws_az"

    env_name = "${var.env_name}"
    aws_az = "1e"
    aws_public_subnet = "10.2.3.0/24"
    aws_workers_subnet = "10.2.4.0/24"
    aws_vpc_id = "${aws_vpc.main.id}"
    aws_gateway_id = "${aws_internet_gateway.gw.id}"

    aws_bastion_ami = "${var.aws_bastion_ami}"
    aws_worker_ami = "${var.aws_worker_ami}"
    aws_nat_ami = "${var.aws_nat_ami}"
}
