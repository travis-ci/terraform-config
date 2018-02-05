variable "ssh_host" {}
variable "ssh_user" {}
variable "version" {}
variable "env" {}
variable "index" {}
variable "host_id" {}
variable "worker_base_config" {}
variable "worker_env_config" {}
variable "worker_local_config" {}

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
    base_config_signature    = "${sha256(var.worker_base_config)}"
    env_config_signature     = "${sha256(var.worker_env_config)}"
    local_config             = "${var.worker_local_config}"
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
    content     = "${data.template_file.worker_upstart.rendered}"
    destination = "/tmp/init-travis-worker-${var.env}.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.worker_install.rendered}"]
  }

  provisioner "file" {
    content = <<EOF
# base config
${var.worker_base_config}

# env config
${var.worker_env_config}

# local config
${var.worker_local_config}
EOF

    destination = "/tmp/etc-default-travis-worker-${var.env}"
  }
}
