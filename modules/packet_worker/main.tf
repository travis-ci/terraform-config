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
variable "nat_ip" {}
variable "nat_public_ip" {}
variable "server_count" {}

variable "server_plan" {
  default = "c2.medium.x86"
}

variable "site" {}
variable "syslog_address" {}
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
  template = <<EOF
export TRAVIS_NETWORK_NAT_IP=${var.nat_ip}
export TRAVIS_NETWORK_ELASTIC_IP=${var.nat_public_ip}
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

resource "local_file" "user_data_dump" {
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
  user_data        = "${data.template_file.cloud_config.rendered}"

  lifecycle {
    ignore_changes = ["root_password"]
  }
}

resource "null_resource" "assign_private_network" {
  triggers {
    user_data_sha1 = "${sha1(data.template_file.cloud_config.rendered)}"
  }

  depends_on = ["packet_device.worker"]

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/packet-assign-private-network \
    --project-id=${var.project_id} \
    --device-id=${packet_device.worker.id} \
    --facility-id=${var.facility}
EOF
  }
}

# resource "null_resource" "user_data_copy" {
#   triggers {
#     user_data_sha1 = "${sha1(data.template_file.cloud_config.rendered)}"
#   }
#
#   depends_on = ["packet_device.worker", "local_file.user_data_dump"]
#
#   provisioner "file" {
#     source      = "${local_file.user_data_dump.filename}"
#     destination = "/var/lib/cloud/instance/user-data.txt"
#   }
#
#   provisioner "remote-exec" {
#     inline = [
#       "cloud-init modules --mode init",
#       "cloud-init modules --mode config",
#       "cloud-init modules --mode final",
#     ]
#   }
#
#   connection {
#     type = "ssh"
#     user = "root"
#     host = "${packet_device.worker.access_public_ipv4}"
#   }
# }

