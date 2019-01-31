variable "jupiter_brain_production_version" {
  default = "v1.0.0-18-ga1e73ab"
}

resource "random_id" "jupiter_brain_production_org_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_production_com_token" {
  byte_length = 32
}

module "jupiter_brain_production_org" {
  source                = "../modules/jupiter_brain_bluegreen"
  host_id               = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address        = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user              = "${var.ssh_user}"
  jupiter_brain_version = "${var.jupiter_brain_production_version}"
  config_path           = "${path.module}/config/jupiter-brain-production-org-env"
  env                   = "production-org"
  index                 = "${var.index}"
  port_suffix           = 1
  token                 = "${random_id.jupiter_brain_production_org_token.hex}"
}

module "jupiter_brain_production_com" {
  source                = "../modules/jupiter_brain_bluegreen"
  host_id               = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_ip_address        = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user              = "${var.ssh_user}"
  jupiter_brain_version = "${var.jupiter_brain_production_version}"
  config_path           = "${path.module}/config/jupiter-brain-production-com-env"
  env                   = "production-com"
  index                 = "${var.index}"
  port_suffix           = 3
  token                 = "${random_id.jupiter_brain_production_com_token.hex}"
}
