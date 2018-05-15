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

variable "nat_server_count" {
  default = 1
}

variable "nat_server_plan" {
  default = "c2.medium.x86"
}

variable "project_id" {}
variable "syslog_address" {}

data "template_file" "duo_config" {
  template = <<EOF
# Written by terraform :heart:
[duo]
ikey = ${var.duo_integration_key}
skey = ${var.duo_secret_key}
host = ${var.duo_api_hostname}
failmode = secure
EOF
}

data "template_file" "librato_env" {
  template = <<EOF
export LIBRATO_EMAIL=${var.librato_email}
export LIBRATO_TOKEN=${var.librato_token}
EOF
}

data "template_file" "nat_dynamic_config" {
  template = "${file("${path.module}/nat-dynamic-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../assets"
    duo_config       = "${data.template_file.duo_config.rendered}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    here             = "${path.module}"
    librato_env      = "${data.template_file.librato_env.rendered}"
    syslog_address   = "${var.syslog_address}"
  }
}

resource "packet_reserved_ip_block" "ips" {
  project_id = "${var.project_id}"
  facility   = "${var.facility}"
  quantity   = "${var.nat_server_count}"
}

resource "tls_private_key" "terraform" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "terraform" {
  keepers {
    pubkey = "${tls_private_key.terraform.public_key_openssh}"
  }

  byte_length = 16
}

data "template_file" "nat_user_data" {
  count = "${var.nat_server_count}"

  template = "${file("${path.module}/nat-user-data.bash.tpl")}"

  vars {
    assets                       = "${path.module}/../../assets"
    elastic_ip                   = "${cidrhost(element(packet_reserved_ip_block.ips.*.cidr_notation, count.index), count.index)}"
    env                          = "${var.env}"
    facility                     = "${var.facility}"
    index                        = "${var.index}"
    instance_fqdn                = "${format("${var.env}-${var.index}-nat-%02d-packet.packet-${var.facility}.travisci.net", count.index + 1)}"
    instance_name                = "${format("${var.env}-${var.index}-nat-%02d-packet", count.index + 1)}"
    terraform_private_key_pem    = "${tls_private_key.terraform.private_key_pem}"
    terraform_public_key_openssh = "${tls_private_key.terraform.public_key_openssh}"
    terraform_password           = "${random_id.terraform.hex}"
    vlan_ip                      = "192.168.${var.index}.${count.index + 1}"
  }
}

resource "packet_device" "nat" {
  count = "${var.nat_server_count}"

  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${format("${var.env}-${var.index}-nat-%02d-packet", count.index + 1)}"
  operating_system = "ubuntu_16_04"
  plan             = "${var.nat_server_plan}"
  project_id       = "${var.project_id}"
  user_data        = "${element(data.template_file.nat_user_data.*.rendered, count.index)}"
  tags             = ["nat", "${var.env}"]

  lifecycle {
    ignore_changes = ["root_password", "user_data"]
  }
}

resource "null_resource" "assign_private_network" {
  count = "${var.nat_server_count}"

  triggers {
    nat_dynamic_config_sha1 = "${sha1(data.template_file.nat_dynamic_config.rendered)}"
  }

  depends_on = ["packet_device.nat"]

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/packet-assign-private-network \
    --project-id=${var.project_id} \
    --device-id=${element(packet_device.nat.*.id, count.index)} \
    --facility-id=${var.facility}
EOF
  }
}

resource "null_resource" "nat_dynamic_config_copy" {
  count = "${var.nat_server_count}"

  triggers {
    nat_dynamic_config_sha1 = "${sha1(data.template_file.nat_dynamic_config.rendered)}"
  }

  depends_on = ["packet_device.nat"]

  connection {
    user        = "terraform"
    host        = "${element(packet_device.nat.*.access_public_ipv4, count.index)}"
    private_key = "${tls_private_key.terraform.private_key_pem}"
    agent       = false
  }

  provisioner "file" {
    content     = "${data.template_file.nat_dynamic_config.rendered}"
    destination = "/var/tmp/travis-nat-dynamic-config.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init -d -f /var/tmp/travis-nat-dynamic-config.yml single -n write_files --frequency always",
      "sudo bash /var/tmp/travis-nat-dynamic-config.bash",
    ]
  }
}

resource "packet_ip_attachment" "nat" {
  count = "${var.nat_server_count}"

  device_id     = "${element(packet_device.nat.*.id, count.index)}"
  cidr_notation = "${cidrhost(packet_reserved_ip_block.ips.cidr_notation, count.index)}/32"
}

data "travis_expanded_cidr" "nat_public_ips" {
  cidr = "${packet_reserved_ip_block.ips.cidr_notation}"
}

output "nat_ips" {
  value = ["${packet_device.nat.*.access_private_ipv4}"]
}

output "nat_public_ips" {
  value = ["${data.travis_expanded_cidr.nat_public_ips.addrs}"]
}

output "nat_maint_ips" {
  value = ["${packet_device.nat.*.access_public_ipv4}"]
}

output "facility" {
  value = "${var.facility}"
}

output "terraform_privkey" {
  value     = "${tls_private_key.terraform.private_key_pem}"
  sensitive = true
}
