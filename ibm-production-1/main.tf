locals {
  BASENAME = "travis-ci-production-1"
}

#################################################
##               End of variables              ##
#################################################

provider "ibm" {
    version          = ">= 0.21.0"
    ibmcloud_api_key = "${var.ibmcloud_api_key}"
    generation       = "${var.ibmcloud_generation}"
    region           = "${var.ibmcloud_region}"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/ibm-production-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

#################################################
##               End of variables              ##
#################################################

module "network" {
    source = "../modules/ibm_network"

    basename        = "${local.BASENAME}"
    ibmcloud_zone   = "${var.ibmcloud_zone}"
    ipv4_cidr_block = "${var.ipv4_cidr_block}"
    allowed_ips     = "${var.allowed_ips}"
}

module "worker" {
    source = "../modules/ibm_worker"

    basename        = "${local.BASENAME}"
    ibmcloud_zone   = "${var.ibmcloud_zone}"
    vpc_id          = "${module.network.vpc_id}"
    subnet_id       = "${module.network.subnet_id}"
    workers         = "${var.workers}"
    workers_org     = "${var.workers_org}"
    image_id        = "${var.image_id}"
    profile_id      = "${var.profile_id}"
    public_key_id   = "${var.public_key_id}"
    salt_master     = "${ibm_is_instance.bastion.primary_network_interface.0.primary_ipv4_address}"

    travis_worker     = "${var.travis_worker}"
    travis_worker_org = "${var.travis_worker_org}"
}

resource "ibm_is_instance" "bastion" {
    name    = "${local.BASENAME}-bastion"
    image   = "${var.image_id}"
    profile = "cp2-2x4"

    primary_network_interface = {
        subnet = "${module.network.subnet_id}"
    }

    vpc  = "${module.network.vpc_id}"
    zone = "${var.ibmcloud_zone}"
    keys = ["${var.public_key_id}"]

    timeouts {
        create = "90m"
        delete = "30m"
    }

    lifecycle {
        ignore_changes = ["user_data"]
    }

    user_data = "${file("tpl/bastion.sh.tpl")}"
}

resource "ibm_is_floating_ip" "bastion" {
    name   = "${local.BASENAME}-bastion"
    target = "${ibm_is_instance.bastion.primary_network_interface.0.id}"
}
