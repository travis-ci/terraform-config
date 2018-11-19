variable "ssh_ip_address" {}
variable "ssh_user" {}
variable "jupiter_brain_version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "port_suffix" {}
variable "host_id" {}
variable "token" {}

data "template_file" "jupiter_brain_install" {
  template = "${file("${path.module}/install-jupiter-brain.sh")}"

  vars {
    env     = "${var.env}"
    version = "${var.jupiter_brain_version}"
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
    version                  = "${var.jupiter_brain_version}"
    config_signature         = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.jupiter_brain_install.rendered)}"
    upstart_script_signature = "${sha256(data.template_file.jupiter_brain_upstart.rendered)}"
    name                     = "${var.env}-${var.index}"
    port_suffix              = "${var.port_suffix}"
    host_id                  = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_ip_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source      = "${var.config_path}"
    destination = "/tmp/etc-default-jupiter-brain-${var.env}"
  }

  provisioner "file" {
    content = <<EOF
export JUPITER_BRAIN_ADDR='127.0.0.1:${9080 + var.port_suffix}'
export JUPITER_BRAIN_LIBRATO_SOURCE='jupiter-brain-${var.env}-${var.index}-blue'
export JUPITER_BRAIN_AUTH_TOKEN='${var.token}'
EOF

    destination = "/tmp/etc-default-jupiter-brain-${var.env}-blue"
  }

  provisioner "file" {
    content = <<EOF
export JUPITER_BRAIN_ADDR='127.0.0.1:${10080 + var.port_suffix}'
export JUPITER_BRAIN_LIBRATO_SOURCE='jupiter-brain-${var.env}-${var.index}-green'
export JUPITER_BRAIN_AUTH_TOKEN='${var.token}'
EOF

    destination = "/tmp/etc-default-jupiter-brain-${var.env}-green"
  }

  # NOTE: terraform 0.9.7 introduced a validator for this provisioner that does
  # not play well with `content` and `data.template_file` (maybe?).  See:
  # https://github.com/hashicorp/terraform/issues/15177
  #   provisioner "file" {
  #     content     = "${data.template_file.jupiter_brain_upstart.rendered}"
  #     destination = "/tmp/init-jupiter-brain-${var.env}.conf"
  #   }
  # HACK{
  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/init-jupiter-brain-${var.env}.conf.b64 <<EONESTEDF
${base64encode(data.template_file.jupiter_brain_upstart.rendered)}
EONESTEDF
base64 --decode </tmp/init-jupiter-brain-${var.env}.conf.b64 \
  >/tmp/init-jupiter-brain-${var.env}.conf
EOF
      ,
    ]
  }

  # }HACK

  provisioner "remote-exec" {
    inline = ["${data.template_file.jupiter_brain_install.rendered}"]
  }
}
