variable "ssh_host" {}
variable "ssh_user" {}

variable "config" {
  type = "list"
}

variable "host_id" {}

data "template_file" "haproxy_mappings" {
  template = <<EOF
frontend $${name}
  log global
  maxconn 400
  bind 127.0.0.1:$${frontend_port}
  default_backend servers-$${name}

backend servers-$${name}
  mode http
  server blue 127.0.0.1:$${backend_port_blue} weight 1 maxconn 200 check
  server green 127.0.0.1:$${backend_port_green} weight 1 maxconn 200 check

EOF

  count = "${length(var.config)}"

  vars {
    name               = "${lookup(var.config[count.index], "name")}"
    frontend_port      = "${lookup(var.config[count.index], "frontend_port")}"
    backend_port_blue  = "${lookup(var.config[count.index], "backend_port_blue")}"
    backend_port_green = "${lookup(var.config[count.index], "backend_port_green")}"
  }
}

resource "null_resource" "haproxy" {
  triggers {
    config_file_signature = "${sha256(file("${path.module}/haproxy.cfg"))}"
    config_signature      = "${sha256(join("\n", data.template_file.haproxy_mappings.*.rendered))}"
    host_id               = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
  }

# NOTE: terraform 0.9.7 introduced a validator for this provisioner that does
# not play well with `content` and `data.template_file` (maybe?).  See:
# https://github.com/hashicorp/terraform/issues/15177
#   provisioner "file" {
#     content     = "${file("${path.module}/haproxy.cfg")}\n${join("\n", data.template_file.haproxy_mappings.*.rendered)}"
#     destination = "/tmp/haproxy.cfg"
#   }
# HACK{
  provisioner "remote-exec" {
    inline = [
<<EOF
cat >/tmp/haproxy.cfg.b64 <<EONESTEDF
${base64encode("${file("${path.module}/haproxy.cfg")}\n${join("\n", data.template_file.haproxy_mappings.*.rendered)}")}
EONESTEDF
base64 --decode </tmp/haproxy.cfg.b64 \
  >/tmp/haproxy.cfg
EOF
    ]
  }
# }HACK

  provisioner "remote-exec" {
    inline = [
      "DEBIAN_FRONTEND=noninteractive sudo apt-get -y install haproxy",
      "sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
      "echo ENABLED=1 | sudo tee /etc/default/haproxy",
    ]
  }
}
