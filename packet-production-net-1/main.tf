variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}

variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "librato_email" {}
variable "librato_token" {}
variable "project_id" {}
variable "syslog_address_com" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-production-net-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "packet" {}
provider "aws" {}

module "packet_network_ewr1" {
  source              = "../modules/packet_network"
  duo_api_hostname    = "${var.duo_api_hostname}"
  duo_integration_key = "${var.duo_integration_key}"
  duo_secret_key      = "${var.duo_secret_key}"
  env                 = "${var.env}"
  facility            = "ewr1"
  github_users        = "${var.github_users}"
  index               = "${var.index}"
  librato_email       = "${var.librato_email}"
  librato_token       = "${var.librato_token}"
  project_id          = "${var.project_id}"
  syslog_address      = "${var.syslog_address_com}"
}

resource "aws_route53_record" "nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat-${var.env}-${var.index}.packet-ewr1.travisci.net"
  type    = "A"
  ttl     = 300

  records = ["${module.packet_network_ewr1.nat_public_ip}"]
}

output "facility" {
  value = "${module.packet_network_ewr1.facility}"
}

output "nat_ip" {
  value = "${module.packet_network_ewr1.nat_ip}"
}

output "nat_maint_ip" {
  value = "${module.packet_network_ewr1.nat_maint_ip}"
}

output "nat_public_ip" {
  value = "${module.packet_network_ewr1.nat_public_ip}"
}

output "terraform_privkey" {
  value = "${module.packet_network_ewr1.terraform_privkey}"
}
