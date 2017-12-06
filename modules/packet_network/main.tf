variable "billing_cycle" {
  default = "hourly"
}

variable "duo_api_hostname" {}
variable "duo_integration_key" {}
variable "duo_secret_key" {}
variable "env" {}
variable "facility" {}
variable "github_users" {}
variable "index" {}

variable "nat_server_plan" {
  default = "baremetal_2"
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
    assets           = "${path.module}/../../assets"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address}"
    duo_config       = "${data.template_file.duo_config.rendered}"
  }
}

resource "packet_device" "nat" {
  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${var.env}-${var.index}-nat"
  operating_system = "ubuntu_16_04"
  plan             = "${var.nat_server_plan}"
  project_id       = "${var.project_id}"
  user_data        = "${data.template_file.cloud_config.rendered}"
}

resource "packet_reserved_ip_block" "ips" {
  project_id = "${var.project_id}"
  facility   = "${var.facility}"
  quantity   = 1
}

resource "packet_ip_attachment" "nat" {
  device_id     = "${packet_device.nat.id}"
  cidr_notation = "${packet_reserved_ip_block.ips.cidr_notation}"
}

resource "null_resource" "nat_post_provisioning_todo" {
  triggers {
    nat_public_ip = "${cidrhost(packet_ip_attachment.nat.cidr_notation, 0)}"
  }

  provisioner "local-exec" {
    command = <<EOF
cat <<EOCAT
TODO: finish configuring the nat with something like

    ip addr add ${cidrhost(packet_ip_attachment.nat.cidr_notation, 0)} dev bond0
    ip route delete default
    ip route add default via ${cidrhost(packet_ip_attachment.nat.cidr_notation, 0)} dev bond0
    curl icanhazip.com  # <=== should be ${cidrhost(packet_ip_attachment.nat.cidr_notation, 0)}

EOCAT
EOF
  }
}

output "nat_ip" {
  value = "${packet_device.nat.access_private_ipv4}"
}

output "nat_public_ip" {
  value = "${cidrhost(packet_ip_attachment.nat.cidr_notation, 0)}"
}

output "facility" {
  value = "${var.facility}"
}
