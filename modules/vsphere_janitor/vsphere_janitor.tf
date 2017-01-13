variable "ssh_host" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "host_id" {}

data "template_file" "vsphere_janitor_install" {
  template = "${file("${path.module}/install-vsphere-janitor.sh")}"

  vars {
    env = "${var.env}"
    version = "${var.version}"
    index = "${var.index}"
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
    version = "${var.version}"
    config_signature = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.vsphere_janitor_install.rendered)}"
    upstart_script_signature = "${sha256(data.template_file.vsphere_janitor_upstart.rendered)}"
    name = "${var.env}-${var.index}"
    host_id = "${var.host_id}"
  }

  connection {
    host = "${var.ssh_host}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source = "${var.config_path}"
    destination = "/tmp/etc-default-vsphere-janitor-${var.env}"
  }

  provisioner "file" {
    content = "${data.template_file.vsphere_janitor_upstart.rendered}"
    destination = "/tmp/init-vsphere-janitor-${var.env}.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.vsphere_janitor_install.rendered}"]
  }
}
