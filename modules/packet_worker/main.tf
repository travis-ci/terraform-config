variable "billing_cycle" {
  default = "hourly"
}

variable "env" {}
variable "facility" {}
variable "index" {}

variable "project_id" {}
variable "nat_ip" {}
variable "server_count" {}

variable "server_plan" {
  default = "baremetal_2"
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
  default = "travisci/worker:v3.4.0"
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
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets         = "${path.module}/../../assets"
    cloud_init_env = "${data.template_file.cloud_init_env.rendered}"
    here           = "${path.module}"
    network_env    = "${data.template_file.network_env.rendered}"
    syslog_address = "${var.syslog_address}"
    worker_config  = "${var.worker_config}"
  }
}

resource "packet_device" "worker" {
  count            = "${var.server_count}"
  billing_cycle    = "${var.billing_cycle}"
  facility         = "${var.facility}"
  hostname         = "${format("${var.env}-${var.index}-worker-${var.site}-%02d", count.index + 1)}"
  operating_system = "ubuntu_16_04"
  plan             = "${var.server_plan}"
  project_id       = "${var.project_id}"
  user_data        = "${data.template_file.cloud_config.rendered}"
}
