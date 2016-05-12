module "aws_az_1b" {
    source = "../modules/aws_az"

    env_name = "${var.env_name}"
    aws_az = "1b"
    aws_vpc_id = "${aws_vpc.main.id}"
    aws_gateway_id = "${aws_internet_gateway.gw.id}"

    aws_bastion_ami = "${var.aws_bastion_ami}"
    aws_worker_ami = "${var.aws_worker_ami}"
    aws_nat_ami = "${var.aws_nat_ami}"
}
