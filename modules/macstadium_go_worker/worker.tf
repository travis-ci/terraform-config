variable "ssh_ip_address" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "vm_ssh_key_path" {}
variable "env" {}
variable "index" {}

data "template_file" "worker_install" {
  template = "${file("${path.module}/install-worker.sh")}\nexport TRAVIS_WORKER_LIBRATO_SOURCE='travis-worker-macstadium-$${index}-$${env}'"

  vars {
    env = "${var.env}"
    version = "${var.version}"
    index = "${var.index}"
  }
}

data "template_file" "worker_upstart" {
  template = "${file("${path.module}/worker.conf.tpl")}"

  vars {
    env = "${var.env}"
  }
}

resource "null_resource" "worker" {
  triggers {
    version = "${var.version}"
    config_signature = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.worker_install.rendered)}"
    upstart_script_signature = "${sha256(data.template_file.worker_upstart.rendered)}"
    ssh_key_signature = "${sha256(file(var.vm_ssh_key_path))}"
    name = "${var.env}-${var.index}"
  }

  connection {
    host = "${var.ssh_ip_address}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source = "${var.config_path}"
    destination = "/tmp/etc-default-travis-worker-${var.env}"
  }

  provisioner "file" {
    content = "${data.template_file.worker_upstart.rendered}"
    destination = "/tmp/init-travis-worker-${var.env}.conf"
  }

  provisioner "file" {
    source = "${var.vm_ssh_key_path}"
    destination = "/tmp/travis-vm-ssh-key"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.worker_install.rendered}"]
  }
}
