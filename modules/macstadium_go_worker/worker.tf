variable "ssh_host" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "host_id" {}
variable "pool_size" {}
variable "travis_site" {}
variable "queue_type" {}

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

data "template_file" "worker_config" {
  template = "${file("${path.module}/etc-default-worker.tpl")}"

  vars {
    pool_size = "${var.pool_size}"
    queue_type = "${var.queue_type}"
    travis_site = "${var.travis_site}"
  }
}

resource "null_resource" "worker" {
  triggers {
    version                  = "${var.version}"
    config_signature         = "${sha256(data.template_file.worker_config.rendered)}"
    install_script_signature = "${sha256(data.template_file.worker_install.rendered)}"
    upstart_script_signature = "${sha256(data.template_file.worker_upstart.rendered)}"
    name                     = "${var.env}-${var.index}"
    host_id                  = "${var.host_id}"
    pool_size                = "${var.pool_size}"
    queue_type               = "${var.queue_type}"
    travis_site           = "${var.travis_site}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content      = "${var.config_path}\n${data.template_file.worker_config.rendered}"
    destination = "/tmp/etc-default-travis-worker-${var.env}"
  }

  # NOTE: terraform 0.9.7 introduced a validator for this provisioner that does
  # not play well with `content` and `data.template_file` (maybe?).  See:
  # https://github.com/hashicorp/terraform/issues/15177
  #   provisioner "file"  {
  #     content     = "${data.template_file.worker_upstart.rendered}"
  #     destination = "/tmp/init-travis-worker-${var.env}.conf"
  #   }
  # HACK{
  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/init-travis-worker-${var.env}.conf.b64 <<EONESTEDF
${base64encode(data.template_file.worker_upstart.rendered)}
EONESTEDF
base64 --decode </tmp/init-travis-worker-${var.env}.conf.b64 \
  >/tmp/init-travis-worker-${var.env}.conf
EOF
      ,
    ]
  }

  # }HACK

  provisioner "remote-exec" {
    inline = ["${data.template_file.worker_install.rendered}"]
  }
}
