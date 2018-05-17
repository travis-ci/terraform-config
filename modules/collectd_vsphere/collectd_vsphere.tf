variable "ssh_host" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "librato_email" {}
variable "librato_token" {}
variable "env" {}
variable "index" {}
variable "host_id" {}
variable "collectd_vsphere_collectd_network_user" {}
variable "collectd_vsphere_collectd_network_token" {}
variable "fw_ip" {}
variable "fw_snmp_community" {}

data "template_file" "collectd_vsphere_install" {
  template = "${file("${path.module}/install-collectd-vsphere.sh")}"

  vars {
    env     = "${var.env}"
    version = "${var.version}"
    index   = "${var.index}"
  }
}

data "template_file" "collectd_conf" {
  template = "${file("${path.module}/collectd.conf.tpl")}"
}

data "template_file" "librato_conf" {
  template = "${file("${path.module}/librato.conf.tpl")}"

  vars {
    host  = "wjb-${var.index}"
    email = "${var.librato_email}"
    token = "${var.librato_token}"
  }
}

data "template_file" "snmp_conf" {
  template = "${file("${path.module}/snmp.conf.tpl")}"

  vars {
    fw_ip             = "${var.fw_ip}"
    fw_snmp_community = "${var.fw_snmp_community}"
  }
}

data "template_file" "collectd_network_token_file" {
  vars {
    collectd_vsphere_token = "${var.collectd_vsphere_collectd_network_token}"
  }
}

data "template_file" "collectd_vsphere_upstart" {
  template = "${file("${path.module}/collectd-vsphere.conf.tpl")}"

  vars {
    env   = "${var.env}"
    index = "${var.index}"
  }
}

resource "null_resource" "collectd_vsphere" {
  triggers {
    version                                           = "${var.version}"
    config_signature                                  = "${sha256(file(var.config_path))}"
    install_script_signature                          = "${sha256(data.template_file.collectd_vsphere_install.rendered)}"
    librato_creds_signature                           = "${sha256(data.template_file.librato_conf.rendered)}"
    collectd_config_signature                         = "${sha256(data.template_file.collectd_conf.rendered)}"
    collectd_vsphere_collectd_network_username        = "${var.collectd_vsphere_collectd_network_user}"
    collectd_vsphere_collectd_network_token_signature = "${sha256(var.collectd_vsphere_collectd_network_token)}"
    collectd_vsphere_init_signature                   = "${sha256(data.template_file.collectd_vsphere_upstart.rendered)}"
    collectd_network_token_file_signature             = "${sha256(data.template_file.collectd_network_token_file.rendered)}"
    collectd_snmp_config_signature                    = "${sha256(data.template_file.snmp_conf.rendered)}"
    name                                              = "${var.env}-${var.index}"
    host_id                                           = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content = <<EOF
${file(var.config_path)}
export COLLECTD_VSPHERE_COLLECTD_USERNAME=${var.collectd_vsphere_collectd_network_user}
export COLLECTD_VSPHERE_COLLECTD_PASSWORD=${var.collectd_vsphere_collectd_network_token}
export COLLECTD_VSPHERE_LIBRATO_SOURCE='collectd-vsphere-${var.env}-${var.index}'
EOF

    destination = "/tmp/etc-default-collectd-vsphere-${var.env}"
  }

  # NOTE: terraform 0.9.7 introduced a validator for this provisioner that does
  # not play well with `content` and `data.template_file` (maybe?).  See:
  # https://github.com/hashicorp/terraform/issues/15177
  #   provisioner "file" {
  #     content     = "${data.template_file.collectd_vsphere_upstart.rendered}"
  #     destination = "/tmp/init-collectd-vsphere-${var.env}.conf"
  #   }
  #
  #   provisioner "file" {
  #     content     = "${data.template_file.collectd_conf.rendered}"
  #     destination = "/tmp/collectd.conf"
  #   }
  #
  #   provisioner "file" {
  #     content     = "${data.template_file.librato_conf.rendered}"
  #     destination = "/tmp/librato.conf"
  #   }
  #
  #   provisioner "file" {
  #     content     = "${data.template_file.snmp_conf.rendered}"
  #     destination = "/tmp/snmp.conf"
  #   }
  # HACK{
  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/init-collectd-vsphere-${var.env}.conf.b64 <<EONESTEDF
${base64encode(data.template_file.collectd_vsphere_upstart.rendered)}
EONESTEDF
base64 --decode </tmp/init-collectd-vsphere-${var.env}.conf.b64 \
  >/tmp/init-collectd-vsphere-${var.env}.conf
EOF
      ,
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/collectd.conf.b64 <<EONESTEDF
${base64encode(data.template_file.collectd_conf.rendered)}
EONESTEDF
base64 --decode </tmp/collectd.conf.b64 \
  >/tmp/collectd.conf
EOF
      ,
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/librato.conf.b64 <<EONESTEDF
${base64encode(data.template_file.librato_conf.rendered)}
EONESTEDF
base64 --decode </tmp/librato.conf.b64 \
  >/tmp/librato.conf
EOF
      ,
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/snmp.conf.b64 <<EONESTEDF
${base64encode(data.template_file.snmp_conf.rendered)}
EONESTEDF
base64 --decode </tmp/snmp.conf.b64 \
  >/tmp/snmp.conf
EOF
      ,
    ]
  }

  # }HACK

  provisioner "file" {
    content     = "${var.collectd_vsphere_collectd_network_user}: ${var.collectd_vsphere_collectd_network_token}"
    destination = "/tmp/collectd-network-auth"
  }
  provisioner "remote-exec" {
    inline = ["${data.template_file.collectd_vsphere_install.rendered}"]
  }
}
