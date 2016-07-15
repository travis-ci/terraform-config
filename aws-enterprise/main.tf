module "aws_az_1b" {
    source = "../modules/aws_az"

    env = "${var.env}"
    aws_az = "1b"
    aws_public_subnet = "10.2.1.0/24"
    aws_workers_org_subnet = "10.2.2.0/24"
    aws_vpc_id = "${aws_vpc.main.id}"
    aws_gateway_id = "${aws_internet_gateway.gw.id}"

    aws_bastion_ami = "${var.aws_bastion_ami}"
    aws_nat_ami = "${var.aws_nat_ami}"
    aws_nat_instance_type = "c3.large" # c3.8xlarge

    bastion_key_name = "${var.bastion_key_name}"
}

module "aws_asg_org" {
    source = "../modules/aws_asg"

    env = "${var.env}"
    site = "org"
    aws_security_groups = "${module.aws_az_1b.workers_org_security_group_id}"
    aws_workers_subnets = "${module.aws_az_1b.workers_org_subnet_id}"

    aws_worker_ami = "${var.aws_worker_ami}"
    cloud_init = "${template_file.cloud_init_org.rendered}"

    bastion_key_name = "${var.bastion_key_name}"
}
