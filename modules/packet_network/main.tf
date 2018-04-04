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
variable "librato_email" {}
variable "librato_token" {}

variable "nat_server_plan" {
  default = "c2.medium.x86"
}

variable "project_id" {}
variable "syslog_address" {}

resource "packet_reserved_ip_block" "ips" {
  project_id = "${var.project_id}"
  facility   = "${var.facility}"
  quantity   = 1
}

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

data "template_file" "network_env" {
  template = <<EOF
export TRAVIS_NETWORK_ELASTIC_IP=${cidrhost(packet_reserved_ip_block.ips.cidr_notation, 0)}
export TRAVIS_NETWORK_VLAN_IP=192.168.${var.index}.1
EOF
}

data "template_file" "librato_env" {
  template = <<EOF
export LIBRATO_EMAIL=${var.librato_email}
export LIBRATO_TOKEN=${var.librato_token}
EOF
}

data "template_file" "instance_env" {
  template = <<EOF
export TRAVIS_INSTANCE_INFRA_ENV=${var.env}
export TRAVIS_INSTANCE_INFRA_INDEX=${var.index}
export TRAVIS_INSTANCE_INFRA_NAME=packet
export TRAVIS_INSTANCE_INFRA_REGION=${var.facility}
export TRAVIS_INSTANCE_ROLE=nat
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../assets"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    here             = "${path.module}"
    instance_env     = "${data.template_file.instance_env.rendered}"
    librato_env      = "${data.template_file.librato_env.rendered}"
    network_env      = "${data.template_file.network_env.rendered}"
    syslog_address   = "${var.syslog_address}"
    duo_config       = "${data.template_file.duo_config.rendered}"
  }
}

resource "local_file" "user_data_dump" {
  filename = "${path.module}/../../tmp/packet-${var.env}-${var.index}-nat-user-data.yml"
  content  = "${data.template_file.cloud_config.rendered}"
}

resource "packet_device" "nat" {
  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${var.env}-${var.index}-nat"
  operating_system = "ubuntu_16_04"
  plan             = "${var.nat_server_plan}"
  project_id       = "${var.project_id}"
  user_data        = "${data.template_file.cloud_config.rendered}"

  lifecycle {
    ignore_changes = ["root_password"]
  }
}

resource "null_resource" "assign_private_network" {
  triggers {
    user_data_sha1 = "${sha1(data.template_file.cloud_config.rendered)}"
  }

  depends_on = ["packet_device.nat"]

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/packet-assign-private-network \
    --project-id=${var.project_id} \
    --device-id=${packet_device.nat.id} \
    --facility-id=${var.facility}
EOF
  }
}

# resource "null_resource" "user_data_copy" {
#   triggers {
#     user_data_sha1 = "${sha1(data.template_file.cloud_config.rendered)}"
#   }
#
#   depends_on = ["packet_device.nat", "local_file.user_data_dump"]
#
#   provisioner "file" {
#     source      = "${local_file.user_data_dump.filename}"
#     destination = "/var/lib/cloud/instance/user-data.txt"
#   }
#
#   provisioner "remote-exec" {
#     inline = [
#       "cloud-init modules --mode init",
#       "cloud-init modules --mode config",
#       "cloud-init modules --mode final",
#     ]
#   }
#
#   connection {
#     type = "ssh"
#     user = "root"
#     host = "${packet_device.nat.access_public_ipv4}"
#   }
# }

resource "packet_ip_attachment" "nat" {
  device_id     = "${packet_device.nat.id}"
  cidr_notation = "${packet_reserved_ip_block.ips.cidr_notation}"
}

output "nat_ip" {
  value = "${packet_device.nat.access_private_ipv4}"
}

output "nat_public_ip" {
  value = "${cidrhost(packet_ip_attachment.nat.cidr_notation, 0)}"
}

output "nat_maint_ip" {
  value = "${packet_device.nat.access_public_ipv4}"
}

output "facility" {
  value = "${var.facility}"
}
