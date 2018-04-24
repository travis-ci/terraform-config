variable "bastion_ip" {}

variable "billing_cycle" {
  default = "hourly"
}

variable "docker_storage_dm_basesize" {
  default = "19G"
}

variable "env" {}
variable "facility" {}
variable "github_users" {}
variable "index" {}

variable "project_id" {}

variable "nat_ips" {
  type = "list"
}

variable "nat_public_ips" {
  type = "list"
}

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
  default = "travisci/worker:v3.6.0"
}

data "tls_public_key" "terraform" {
  private_key_pem = "${var.terraform_privkey}"
}

data "template_file" "cloud_init_env" {
  template = <<EOF
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
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "network_env" {
  # TODO: use different NAT ips when multiples present?

  template = <<EOF
export TRAVIS_NETWORK_NAT_IP=${var.nat_ips[0]}
export TRAVIS_NETWORK_ELASTIC_IP=${var.nat_public_ips[0]}
export TRAVIS_NETWORK_VLAN_GATEWAY=192.168.${var.index}.1
EOF
}

data "template_file" "instance_env" {
  template = <<EOF
export TRAVIS_INSTANCE_INFRA_ENV=${var.env}
export TRAVIS_INSTANCE_INFRA_INDEX=${var.index}
export TRAVIS_INSTANCE_INFRA_NAME=packet
export TRAVIS_INSTANCE_INFRA_REGION=${var.facility}
export TRAVIS_INSTANCE_ROLE=worker
export TRAVIS_INSTANCE_TERRAFORM_PASSWORD=${random_id.terraform.hex}
EOF
}

data "template_file" "docker_daemon_json" {
  template = <<EOF
{
  "data-root": "/mnt/docker",
  "hosts": [
    "tcp://127.0.0.1:4243",
    "unix:///var/run/docker.sock"
  ],
  "icc": false,
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.basesize=${var.docker_storage_dm_basesize}",
    "dm.datadev=/dev/direct-lvm/data",
    "dm.metadatadev=/dev/direct-lvm/metadata",
    "dm.fs=xfs"
  ],
  "userns-remap": "default"
}
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets             = "${path.module}/../../assets"
    cloud_init_env     = "${data.template_file.cloud_init_env.rendered}"
    docker_daemon_json = "${data.template_file.docker_daemon_json.rendered}"
    github_users_env   = "export GITHUB_USERS='${var.github_users}'"
    here               = "${path.module}"
    instance_env       = "${data.template_file.instance_env.rendered}"
    network_env        = "${data.template_file.network_env.rendered}"
    syslog_address     = "${var.syslog_address}"
    worker_config      = "${var.worker_config}"
  }
}

resource "random_id" "terraform" {
  keepers {
    pubkey = "${data.tls_public_key.terraform.public_key_openssh}"
  }

  byte_length = 16
}

resource "local_file" "cloud_config_dump" {
  filename = "${path.module}/../../tmp/packet-${var.env}-${var.index}-worker-${var.site}-user-data.yml"
  content  = "${data.template_file.cloud_config.rendered}"
}

resource "packet_device" "worker" {
  count = "${var.server_count}"

  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${format("${var.env}-${var.index}-worker-${var.site}-%02d", count.index + 1)}"
  operating_system = "ubuntu_16_04"
  plan             = "${var.server_plan}"
  project_id       = "${var.project_id}"

  user_data = <<EOUSERDATA
#!/usr/bin/env bash
cat >/var/tmp/terraform_rsa.pub <<EOPUBKEY
${data.tls_public_key.terraform.public_key_openssh}
EOPUBKEY

cat >/etc/default/travis-network <<'EOENV'
${data.template_file.network_env.rendered}
EOENV

cat >/etc/default/travis-instance <<'EOENV'
${data.template_file.instance_env.rendered}
EOENV

cat >/etc/default/travis-instance-cloud-init <<'EOENV'
export TRAVIS_INSTANCE_NAME=${format("${var.env}-${var.index}-worker-${var.site}-%02d", count.index + 1)}
export TRAVIS_INSTANCE_FQDN=${format("${var.env}-${var.index}-worker-${var.site}-%02d.packet-${var.facility}.travisci.net", count.index + 1)}
EOENV

source /etc/default/travis-instance

${file("${path.module}/../../assets/bits/ensure-tfw.bash")}

tfw bootstrap
systemctl stop fail2ban || true

${file("${path.module}/../../assets/bits/terraform-user-bootstrap.bash")}
${file("${path.module}/../../assets/bits/travis-packet-privnet-setup.bash")}
EOUSERDATA

  lifecycle {
    ignore_changes = ["root_password", "user_data"]
  }
}

resource "null_resource" "assign_private_network" {
  count = "${var.server_count}"

  triggers {
    user_data_sha1 = "${sha1(data.template_file.cloud_config.rendered)}"
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

resource "null_resource" "cloud_config_copy" {
  count = "${var.server_count}"

  triggers {
    cloud_config_sha1 = "${sha1(data.template_file.cloud_config.rendered)}"
  }

  depends_on = ["packet_device.worker", "local_file.cloud_config_dump"]

  connection {
    agent        = false
    bastion_host = "${var.nat_public_ips[0]}"
    host         = "192.168.${var.index}.${replace(element(packet_device.worker.*.access_private_ipv4, count.index), "/[0-9]+\\.[0-9]+\\.[0-9]+\\./", "")}"
    private_key  = "${data.tls_public_key.terraform.private_key_pem}"
    user         = "terraform"
  }

  provisioner "file" {
    source      = "${local_file.cloud_config_dump.filename}"
    destination = "/var/tmp/cloud-config.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init -d -f /var/tmp/cloud-config.yml single -n write_files --frequency always",
      "sudo bash /var/tmp/travis-cloud-init.bash",
    ]
  }
}
