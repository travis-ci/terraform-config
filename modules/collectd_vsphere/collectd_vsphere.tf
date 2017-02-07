variable "ssh_host" {} 
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "librato_email" {}
variable "librato_token" {}
variable "env" {}
variable "index" {}
variable "host_id" {}

data "template_file" "collectd_vsphere_install" {
  template = "${file("${path.module}/install-collectd-vsphere.sh")}"

  vars {
    env = "${var.env}"
    version = "${var.version}"
    index = "${var.index}"
  }
}

data "template_file" "collectd_conf" {
  template = "${file("${path.module}/collectd.conf")}"
}

data "template_file" "librato_conf" {
  template = "${file("${path.module}/librato.conf.tpl")}"

  vars {
    email = "${var.librato_email}"
    token = "${var.librato_token}"
  }
}

data "template_file" "collectd_vsphere_upstart" {
  template = "${file("${path.module}/collectd-vsphere.conf.tpl")}"

  vars {
    env = "${var.env}"
  }
}

resource "null_resource" "collectd_vsphere" {
  triggers {
    version = "${var.version}"
    config_signature = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.collectd_vsphere_install.rendered)}"
    librato_creds_signature = "${sha256(data.template_file.librato_conf.rendered)}"
    collectd_config_signature = "${sha256(data.template_file.collectd_conf.rendered)}"
    collectd_vsphere_init_signature = "${sha256(data.template_file.collectd_vsphere_upstart.rendered)}"
    name = "${var.env}-${var.index}"
    host_id = "${var.host_id}"
  }

  connection {
    host = "${var.ssh_host}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content = "${file(var.config_path)}"
    destination = "/tmp/etc-default-collectd-vsphere-${var.env}"
  }

  provisioner "file" {
    content = "${data.template_file.collectd_vsphere_upstart.rendered}"
    destination = "/tmp/init-collectd-vsphere-${var.env}.conf"
  }

  provisioner "file" {
    content = "${data.template_file.collectd_conf.rendered}"
    destination = "/tmp/collectd.conf"
  }

  provisioner "file" {
    content = "${data.template_file.librato_conf.rendered}"
    destination = "/tmp/librato.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.collectd_vsphere_install.rendered}"]
  }
}
