variable "billing_cycle" {
  default = "hourly"
}

variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}
variable "env" {}
variable "facility" {}
variable "index" {}

variable "nat_util_server_plan" {
  default = "baremetal_1e"
}

variable "project_id" {}
variable "syslog_address" {}

data "template_file" "duo_config" {
  template = <<EOF
# Written by cloud-init :heart:
[duo]
ikey = ${var.duo_integration_key}
skey = ${var.duo_secret_key}
host = ${var.duo_api_hostname}
failmode = secure
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets         = "${path.module}/../../assets"
    github_users_env   = "export GITHUB_USERS='${var.github_users}'"
    here           = "${path.module}"
    syslog_address = "${var.syslog_address}"
    duo_config     = "${data.template_file.duo_config.rendered}"
  }
}

resource "packet_device" "nat_util" {
  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${var.env}-${var-index}-nat"
  operating_system = "ubuntu_16_04"
  plan             = "${var.nat_util_server_plan}"
  project_id       = "${var.project_id}"
  user_data        = "${data.template_file.cloud_config.rendered}"
}

resource "packet_reserved_ip_block" "nat_util" {
  project_id = "${var.project_id}"
  facility   = "${var.facility}"
  quantity   = 1
}

resource "packet_ip_attachment" "nat_util_0" {
  device_id     = "${packet_device.nat_util.id}"
  cidr_notation = "${cidrhost(packet_reserved_ip_block.nat_util.cidr_notation, 0)}/32"
}

output "nat_ip" {
  value = "${packet_device.nat_util.access_private_ipv4}"
}

output "nat_public_ip" {
  value = "${cidrhost(packet_ip_attachment.nat_util_0.cidr_notation, 0)}"
}

output "facility" {
  value = "${var.facility}"
}
