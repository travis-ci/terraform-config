variable "ssh_host" {}
variable "ssh_user" {}
variable "vsphere_janitor_version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "host_id" {}

data "template_file" "vsphere_janitor_install" {
  template = "${file("${path.module}/install-vsphere-janitor.sh")}"

  vars {
    env     = "${var.env}"
    version = "${var.vsphere_janitor_version}"
    index   = "${var.index}"
  }
}

data "template_file" "vsphere_janitor_upstart" {
  template = "${file("${path.module}/vsphere-janitor.conf.tpl")}"

  vars {
    env = "${var.env}"
  }
}

resource "null_resource" "vsphere_janitor" {
  triggers {
    version                  = "${var.vsphere_janitor_version}"
    config_signature         = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.vsphere_janitor_install.rendered)}"
    upstart_script_signature = "${sha256(data.template_file.vsphere_janitor_upstart.rendered)}"
    name                     = "${var.env}-${var.index}"
    host_id                  = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content     = "${file(var.config_path)}\nexport VSPHERE_JANITOR_LIBRATO_SOURCE='vsphere-janitor-${var.env}-${var.index}'\n"
    destination = "/tmp/etc-default-vsphere-janitor-${var.env}"
  }

  # NOTE: terraform 0.9.7 introduced a validator for this provisioner that does
  # not play well with `content` and `data.template_file` (maybe?).  See:
  # https://github.com/hashicorp/terraform/issues/15177
  #   provisioner "file" {
  #     content     = "${data.template_file.vsphere_janitor_upstart.rendered}"
  #     destination = "/tmp/init-vsphere-janitor-${var.env}.conf"
  #   }
  # HACK{
  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/init-vsphere-janitor-${var.env}.conf.b64 <<EONESTEDF
${base64encode(data.template_file.vsphere_janitor_upstart.rendered)}
EONESTEDF
base64 --decode </tmp/init-vsphere-janitor-${var.env}.conf.b64 \
  >/tmp/init-vsphere-janitor-${var.env}.conf
EOF
      ,
    ]
  }

  # }HACK

  provisioner "remote-exec" {
    inline = ["${data.template_file.vsphere_janitor_install.rendered}"]
  }
}
