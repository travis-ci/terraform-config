variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "region" {
  default = "us-central1"
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

data "dns_a_record_set" "gce_production_1_nat" {
  host = "nat-production-1.gce-${var.region}.travisci.net"
}

data "dns_a_record_set" "gce_production_2_nat" {
  host = "nat-production-2.gce-${var.region}.travisci.net"
}

data "dns_a_record_set" "gce_production_3_nat" {
  host = "nat-production-3.gce-${var.region}.travisci.net"
}

data "dns_a_record_set" "gce_production_4_nat" {
  host = "nat-production-5.gce-${var.region}.travisci.net"
}

data "dns_a_record_set" "gce_production_5_nat" {
  host = "nat-production-5.gce-${var.region}.travisci.net"
}

resource "aws_route53_record" "gce_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.gce-${var.region}.travisci.net"
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
