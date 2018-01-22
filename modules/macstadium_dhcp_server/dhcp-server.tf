variable "ssh_host" {}
variable "ssh_user" {}
variable "host_id" {}
variable "index" {}
variable "jobs_network_subnet" {}

data "template_file" "dhcpd_install" {
  template = "${file("${path.module}/install-dhcpd.sh")}"
}

data "template_file" "dhcpd_conf" {
  template = "${file("${path.module}/dhcpd.conf.tpl")}"

  vars {
    # this is the jobs subnet. really all this does is lop the /18 off of the var
    jobs_subnet = "${cidrhost(var.jobs_network_subnet, 0)}"

    # dhcpd takes netmask in decimal form
    jobs_subnet_netmask = "${cidrnetmask(var.jobs_network_subnet)}"
    domain_name         = "macstadium.travisci.net"

    # we reserve the first 256 addresses of the subnet for ourselves. greedy
    jobs_subnet_begin = "${cidrhost(var.jobs_network_subnet, 256)}"

    # ...and the last 128, just in case.
    jobs_subnet_end = "${cidrhost(var.jobs_network_subnet, -128)}"

    # we assume the first address is the gateway (for now, it is)
    jobs_gateway = "${cidrhost(var.jobs_network_subnet, 1)}"

    # lease times are in seconds
    dhcp_lease_default_time = "600"
    dhcp_lease_max_time     = "12600"
  }
}

data "template_file" "dhcpd_defaults" {
  template = "${file("${path.module}/isc-dhcp-server-defaults")}"
}

resource "null_resource" "dhcp_server" {
  triggers {
    install_script_signature = "${sha256(data.template_file.dhcpd_install.rendered)}"
    dhcpd_conf_signature     = "${sha256(data.template_file.dhcpd_conf.rendered)}"
    dhcpd_defaults_signature = "${sha256(data.template_file.dhcpd_defaults.rendered)}"
    jobs_network_subnet      = "${var.jobs_network_subnet}"
    name                     = "dhcp_server-${var.index}"
    host_id                  = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
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
cat >/tmp/dhcpd.conf.b64 <<EONESTEDF
${base64encode(data.template_file.dhcpd_conf.rendered)}
EONESTEDF
base64 --decode </tmp/dhcpd.conf.b64 >/tmp/dhcpd.conf
EOF
      ,
    ]
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
cat >/tmp/isc-dhcp-server-defaults.b64 <<EONESTEDF
${base64encode(data.template_file.dhcpd_defaults.rendered)}
EONESTEDF
base64 --decode < /tmp/isc-dhcp-server-defaults.b64 >/tmp/isc-dhcp-server-defaults
EOF
      ,
    ]
  }

  # }HACK

  provisioner "remote-exec" {
    inline = ["${data.template_file.dhcpd_install.rendered}"]
  }
}
