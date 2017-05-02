variable "ssh_host" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "host_id" {}

data "template_file" "worker_install" {
  template = "${file("${path.module}/install-worker.sh")}\nexport TRAVIS_WORKER_LIBRATO_SOURCE='travis-worker-macstadium-$${index}-$${env}'"

  vars {
    env     = "${var.env}"
    version = "${var.version}"
    index   = "${var.index}"
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
    version                  = "${var.version}"
    config_signature         = "${sha256(file(var.config_path))}"
    install_script_signature = "${sha256(data.template_file.worker_install.rendered)}"
    upstart_script_signature = "${sha256(data.template_file.worker_upstart.rendered)}"
    name                     = "${var.env}-${var.index}"
    host_id                  = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source      = "${var.config_path}"
    destination = "/tmp/etc-default-travis-worker-${var.env}"
  }

  provisioner "file" {
    content     = "${data.template_file.worker_upstart.rendered}"
    destination = "/tmp/init-travis-worker-${var.env}.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.worker_install.rendered}"]
  }
}
