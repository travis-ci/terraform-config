variable "bastion_ip" {}

variable "billing_cycle" {
  default = "hourly"
}

variable "env" {}
variable "facility" {}
variable "github_users" {}
variable "index" {}
variable "librato_email" {}
variable "librato_token" {}

variable "nat_ips" {
  type = "list"
}

variable "nat_public_ips" {
  type = "list"
}

variable "project_id" {}
variable "pupcycler_auth_token" {}
variable "pupcycler_url" {}
variable "server_count" {}

variable "server_plan" {
  default = "c2.medium.x86"
}

variable "site" {}
variable "syslog_address" {}
variable "terraform_privkey" {}
variable "worker_config" {}
variable "worker_docker_image_android" {}
variable "worker_docker_image_default" {}
variable "worker_docker_image_erlang" {}
variable "worker_docker_image_go" {}
variable "worker_docker_image_haskell" {}
variable "worker_docker_image_jvm" {}
variable "worker_docker_image_node_js" {}
variable "worker_docker_image_perl" {}
variable "worker_docker_image_php" {}
variable "worker_docker_image_python" {}
variable "worker_docker_image_ruby" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.8.2"
}

data "tls_public_key" "terraform" {
  private_key_pem = "${var.terraform_privkey}"
}

data "template_file" "cloud_init_env" {
  template = <<EOF
export PUPCYCLER_AUTH_TOKEN="${var.pupcycler_auth_token}"
export PUPCYCLER_URL="${var.pupcycler_url}"
export TRAVIS_WORKER_DOCKER_IMAGE_ANDROID="${var.worker_docker_image_android}"
export TRAVIS_WORKER_DOCKER_IMAGE_DEFAULT="${var.worker_docker_image_default}"
export TRAVIS_WORKER_DOCKER_IMAGE_ERLANG="${var.worker_docker_image_erlang}"
export TRAVIS_WORKER_DOCKER_IMAGE_GO="${var.worker_docker_image_go}"
export TRAVIS_WORKER_DOCKER_IMAGE_HASKELL="${var.worker_docker_image_haskell}"
export TRAVIS_WORKER_DOCKER_IMAGE_JVM="${var.worker_docker_image_jvm}"
export TRAVIS_WORKER_DOCKER_IMAGE_NODE_JS="${var.worker_docker_image_node_js}"
export TRAVIS_WORKER_DOCKER_IMAGE_PERL="${var.worker_docker_image_perl}"
export TRAVIS_WORKER_DOCKER_IMAGE_PHP="${var.worker_docker_image_php}"
export TRAVIS_WORKER_DOCKER_IMAGE_PYTHON="${var.worker_docker_image_python}"
export TRAVIS_WORKER_DOCKER_IMAGE_RUBY="${var.worker_docker_image_ruby}"
export TRAVIS_WORKER_PRESTART_HOOK="/var/tmp/travis-run.d/travis-worker-prestart-hook"
export TRAVIS_WORKER_START_HOOK="/var/tmp/travis-run.d/travis-worker-start-hook"
export TRAVIS_WORKER_STOP_HOOK="/var/tmp/travis-run.d/travis-worker-stop-hook"
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "librato_env" {
  template = <<EOF
export LIBRATO_EMAIL=${var.librato_email}
export LIBRATO_TOKEN=${var.librato_token}
EOF
}

data "template_file" "dynamic_config" {
  template = "${file("${path.module}/dynamic-config.yml.tpl")}"

  vars {
    assets         = "${path.module}/../../assets"
    cloud_init_env = "${data.template_file.cloud_init_env.rendered}"
    here           = "${path.module}"
    librato_env    = "${data.template_file.librato_env.rendered}"
    syslog_address = "${var.syslog_address}"
    worker_config  = "${var.worker_config}"

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "random_id" "terraform" {
  keepers {
    pubkey = "${data.tls_public_key.terraform.public_key_openssh}"
  }

  byte_length = 16
}

data "template_file" "user_data" {
  count = "${var.server_count}"

  template = "${file("${path.module}/user-data.bash.tpl")}"

  vars {
    assets                       = "${path.module}/../../assets"
    elastic_ip                   = "${var.nat_public_ips[0]}"
    env                          = "${var.env}"
    facility                     = "${var.facility}"
    index                        = "${var.index}"
    instance_fqdn                = "${format("${var.env}-${var.index}-worker-${var.site}-%02d-packet.packet-${var.facility}.travisci.net", count.index + 1)}"
    instance_name                = "${format("${var.env}-${var.index}-worker-${var.site}-%02d-packet", count.index + 1)}"
    terraform_password           = "${random_id.terraform.hex}"
    terraform_public_key_openssh = "${data.tls_public_key.terraform.public_key_openssh}"

    # TODO: Use different NAT ips when multiples present?
    nat_ip       = "${var.nat_ips[0]}"
    vlan_gateway = "192.168.${var.index}.1"
  }
}

resource "packet_device" "worker" {
  count = "${var.server_count}"

  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${format("${var.env}-${var.index}-worker-${var.site}-%02d-packet", count.index + 1)}"
  operating_system = "ubuntu_16_04"
  plan             = "${var.server_plan}"
  project_id       = "${var.project_id}"
  user_data        = "${element(data.template_file.user_data.*.rendered, count.index)}"
  tags             = ["worker", "${var.site}", "${var.env}"]

  hardware_reservation_id = "next-available"

  lifecycle {
    ignore_changes = ["root_password", "user_data"]
  }
}

resource "null_resource" "assign_private_network" {
  count = "${var.server_count}"

  triggers {
    user_data_sha1 = "${sha1(data.template_file.dynamic_config.rendered)}"
  }

  depends_on = ["packet_device.worker"]

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/packet-assign-private-network \
    --project-id=${var.project_id} \
    --device-id=${element(packet_device.worker.*.id, count.index)} \
    --facility-id=${var.facility}
EOF
  }
}

resource "null_resource" "dynamic_config_copy" {
  count = "${var.server_count}"

  triggers {
    dynamic_config_sha1 = "${sha1(data.template_file.dynamic_config.rendered)}"
  }

  depends_on = ["packet_device.worker"]

  connection {
    agent        = false
    bastion_host = "${var.nat_public_ips[0]}"
    host         = "192.168.${var.index}.${replace(element(packet_device.worker.*.access_private_ipv4, count.index), "/[0-9]+\\.[0-9]+\\.[0-9]+\\./", "")}"
    private_key  = "${data.tls_public_key.terraform.private_key_pem}"
    user         = "terraform"
  }

  provisioner "file" {
    content     = "${data.template_file.dynamic_config.rendered}"
    destination = "/var/tmp/travis-worker-dynamic-config.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init -d -f /var/tmp/travis-worker-dynamic-config.yml single -n write_files --frequency always",
      "sudo bash /var/tmp/travis-worker-dynamic-config.bash",
    ]
  }
}
