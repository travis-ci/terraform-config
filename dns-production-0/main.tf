variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "macstadium_production_nat_addrs" {
  type = "list"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/dns-production-0.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {}

data "dns_a_record_set" "aws_production_2_nat_com" {
  host = "workers-nat-com-shared-2.aws-us-east-1.travisci.net"
}

data "dns_a_record_set" "aws_production_2_nat_org" {
  host = "workers-nat-org-shared-2.aws-us-east-1.travisci.net"
}

data "dns_a_record_set" "gce_production_1_nat" {
  host = "nat-production-1.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_2_nat" {
  host = "nat-production-2.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_3_nat" {
  host = "nat-production-3.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_4_nat" {
  host = "nat-production-5.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_5_nat" {
  host = "nat-production-5.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "packet_production_1_nat" {
  host = "nat-production-1.packet-ewr1.travisci.net"
}

resource "aws_route53_record" "aws_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.aws-us-east-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.aws_production_2_nat_com.addrs}",
    "${data.dns_a_record_set.aws_production_2_nat_org.addrs}",
  ]
}

resource "aws_route53_record" "gce_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.gce-us-central1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.gce_production_1_nat.addrs}",
    "${data.dns_a_record_set.gce_production_2_nat.addrs}",
    "${data.dns_a_record_set.gce_production_3_nat.addrs}",
    "${data.dns_a_record_set.gce_production_4_nat.addrs}",
    "${data.dns_a_record_set.gce_production_5_nat.addrs}",
  ]
}

resource "aws_route53_record" "linux_containers_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.linux-containers.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.aws_production_2_nat_com.addrs}",
    "${data.dns_a_record_set.aws_production_2_nat_org.addrs}",
    "${data.dns_a_record_set.packet_production_1_nat.addrs}",
  ]
}

resource "aws_route53_record" "macstadium_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = ["${var.macstadium_production_nat_addrs}"]
}

resource "aws_route53_record" "packet_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.packet-ewr1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.packet_production_1_nat.addrs}",
  ]
}

resource "aws_route53_record" "nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.aws_production_2_nat_com.addrs}",
    "${data.dns_a_record_set.aws_production_2_nat_org.addrs}",
    "${data.dns_a_record_set.gce_production_1_nat.addrs}",
    "${data.dns_a_record_set.gce_production_2_nat.addrs}",
    "${data.dns_a_record_set.gce_production_3_nat.addrs}",
    "${data.dns_a_record_set.gce_production_4_nat.addrs}",
    "${data.dns_a_record_set.gce_production_5_nat.addrs}",
    "${var.macstadium_production_nat_addrs}",
    "${data.dns_a_record_set.packet_production_1_nat.addrs}",
  ]
}
