variable "jupiter_brain_production_version" {
  default = "v0.2.0-58-gce0b45a"
}

variable "jupiter_brain_custom-1_version" {
  default = "v0.2.0-58-gce0b45a"
}

variable "jupiter_brain_custom-2_version" {
  default = "v0.2.0-58-gce0b45a"
}

variable "jupiter_brain_custom-4_version" {
  default = "v0.2.0-58-gce0b45a"
}

variable "jupiter_brain_custom-5_version" {
  default = "v0.2.0-58-gce0b45a"
}

variable "jupiter_brain_custom-6_version" {
  default = "v0.2.0-58-gce0b45a"
}

variable "jupiter_brain_staging_version" {
  default = "v1.0.0-3-g9665e76"
}

resource "random_id" "jupiter_brain_production_org_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_production_com_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_staging_org_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_staging_com_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_custom_1_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_custom_2_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_custom_4_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_custom_5_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_custom_6_token" {
  byte_length = 32
}

module "jupiter_brain_production_org" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_production_version}"
  config_path    = "${path.module}/config/jupiter-brain-production-org-env"
  env            = "production-org"
  index          = "${var.index}"
  port_suffix    = 1
  token          = "${random_id.jupiter_brain_production_org_token.hex}"
}

module "jupiter_brain_staging_org" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_staging_version}"
  config_path    = "${path.module}/config/jupiter-brain-staging-org-env"
  env            = "staging-org"
  index          = "${var.index}"
  port_suffix    = 2
  token          = "${random_id.jupiter_brain_staging_org_token.hex}"
}

module "jupiter_brain_production_com" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_production_version}"
  config_path    = "${path.module}/config/jupiter-brain-production-com-env"
  env            = "production-com"
  index          = "${var.index}"
  port_suffix    = 3
  token          = "${random_id.jupiter_brain_production_com_token.hex}"
}

module "jupiter_brain_staging_com" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_staging_version}"
  config_path    = "${path.module}/config/jupiter-brain-staging-com-env"
  env            = "staging-com"
  index          = "${var.index}"
  port_suffix    = 4
  token          = "${random_id.jupiter_brain_staging_com_token.hex}"
}

module "jupiter_brain_custom_1" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_custom-1_version}"
  config_path    = "${path.module}/config/jupiter-brain-custom-1-env"
  env            = "custom-1"
  index          = "${var.index}"
  port_suffix    = 5
  token          = "${random_id.jupiter_brain_custom_1_token.hex}"
}

module "jupiter_brain_custom_2" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_custom-2_version}"
  config_path    = "${path.module}/config/jupiter-brain-custom-2-env"
  env            = "custom-2"
  index          = "${var.index}"
  port_suffix    = 6
  token          = "${random_id.jupiter_brain_custom_2_token.hex}"
}

module "jupiter_brain_custom_4" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_custom-4_version}"
  config_path    = "${path.module}/config/jupiter-brain-custom-4-env"
  env            = "custom-4"
  index          = "${var.index}"
  port_suffix    = 8
  token          = "${random_id.jupiter_brain_custom_4_token.hex}"
}

module "jupiter_brain_custom_5" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_custom-5_version}"
  config_path    = "${path.module}/config/jupiter-brain-custom-5-env"
  env            = "custom-5"
  index          = "${var.index}"
  port_suffix    = 9
  token          = "${random_id.jupiter_brain_custom_5_token.hex}"
}

module "jupiter_brain_custom_6" {
  source         = "../modules/jupiter_brain_bluegreen"
  host_id        = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user       = "${var.ssh_user}"
  version        = "${var.jupiter_brain_custom-6_version}"
  config_path    = "${path.module}/config/jupiter-brain-custom-6-env"
  env            = "custom-6"
  index          = "${var.index}"
  port_suffix    = 11
  token          = "${random_id.jupiter_brain_custom_6_token.hex}"
}
