variable "jupiter_brain_version" {
  default = "v1.0.0-18-ga1e73ab"
}

resource "random_id" "jupiter_brain_staging_org_token" {
  byte_length = 32
}

resource "random_id" "jupiter_brain_staging_com_token" {
  byte_length = 32
}

module "jupiter_brain_staging_org" {
  source                = "../modules/jupiter_brain_bluegreen"
  host_id               = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_ip_address        = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user              = "${var.ssh_user}"
  jupiter_brain_version = "${var.jupiter_brain_version}"
  config_path           = "${path.module}/config/jupiter-brain-staging-org-env"
  env                   = "staging-org"
  index                 = "${var.index}"
  port_suffix           = 2
  token                 = "${random_id.jupiter_brain_staging_org_token.hex}"
}

module "jupiter_brain_staging_com" {
  source                = "../modules/jupiter_brain_bluegreen"
  host_id               = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_ip_address        = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user              = "${var.ssh_user}"
  jupiter_brain_version = "${var.jupiter_brain_version}"
  config_path           = "${path.module}/config/jupiter-brain-staging-com-env"
  env                   = "staging-com"
  index                 = "${var.index}"
  port_suffix           = 4
  token                 = "${random_id.jupiter_brain_staging_com_token.hex}"
}
