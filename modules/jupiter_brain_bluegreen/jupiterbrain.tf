variable "ssh_ip_address" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "port_suffix" {}

data "template_file" "jupiter_brain_install" {
  template = "${file("${path.module}/install-jupiter-brain.sh")}"

  vars {
    env = "${var.env}"
    version = "${var.version}"
  }
}

data "template_file" "jupiter_brain_upstart" {
  template = "${file("${path.module}/jupiter-brain.conf.tpl")}"

  vars {
    env = "${var.env}"
  }
}

resource "null_resource" "jupiter_brain" {
  triggers {
    version = "${var.version}"
    config_signature = "${sha256(file(var.config_path))}"
    name = "${var.env}-${var.index}"
    port_suffix = "${var.port_suffix}"
  }

  connection {
    host = "${var.ssh_ip_address}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source = "${var.config_path}"
    destination = "/tmp/etc-default-jupiter-brain-${var.env}"
  }

  provisioner "file" {
    content = <<EOF
export JUPITER_BRAIN_ADDR='127.0.0.1:908${var.port_suffix}'
export JUPITER_BRAIN_LIBRATO_SOURCE='jupiter-brain-${var.env}-${var.index}-blue'
EOF
    destination = "/tmp/etc-default-jupiter-brain-${var.env}-blue"
  }

  provisioner "file" {
    content = <<EOF
export JUPITER_BRAIN_ADDR='127.0.0.1:1008${var.port_suffix}'
export JUPITER_BRAIN_LIBRATO_SOURCE='jupiter-brain-${var.env}-${var.index}-green'
EOF
    destination = "/tmp/etc-default-jupiter-brain-${var.env}-green"
  }

  provisioner "file" {
    content = "${data.template_file.jupiter_brain_upstart.rendered}"
    destination = "/tmp/init-jupiter-brain-${var.env}.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.jupiter_brain_install.rendered}"]
  }
}
