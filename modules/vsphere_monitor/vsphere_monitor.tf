variable "ssh_host" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "index" {}
variable "host_id" {}

data "template_file" "vsphere_monitor_install" {
  template = "${file("${path.module}/install-vsphere-monitor.sh")}"

  vars {
    version = "${var.version}"
    index = "${var.index}"
  }
}

resource "null_resource" "vsphere_monitor" {
  triggers {
    version = "${var.version}"
    config_signature = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.vsphere_monitor_install.rendered)}"
    upstart_script_signature = "${sha256(file("${path.module}/vsphere-monitor.conf"))}"
    name = "${var.index}"
    host_id = "${var.host_id}"
  }

  connection {
    host = "${var.ssh_host}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content = "${file(var.config_path)}"
    destination = "/tmp/etc-default-vsphere-monitor"
  }

  provisioner "file" {
    content = "${file("${path.module}/vsphere-monitor.conf")}"
    destination = "/tmp/init-vsphere-monitor.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.vsphere_monitor_install.rendered}"]
  }
}
