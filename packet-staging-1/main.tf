variable "latest_docker_image_amethyst" {}
variable "latest_docker_image_garnet" {}
variable "latest_docker_image_worker" {}
variable "packet_staging_1_project_id" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.0.2"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "packet" {}

data "template_file" "worker_config_org" {
  template = <<EOF
### config/worker-org-local.env
${file("${path.module}/config/worker-org-local.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_TRAVIS_SITE=org
EOF
}

data "template_file" "cloud_init_env" {
  template = <<EOF
export TRAVIS_WORKER_DOCKER_IMAGE_ANDROID="${var.latest_docker_image_amethyst}"
export TRAVIS_WORKER_DOCKER_IMAGE_DEFAULT="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_DOCKER_IMAGE_ERLANG="${var.latest_docker_image_amethyst}"
export TRAVIS_WORKER_DOCKER_IMAGE_GO="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_DOCKER_IMAGE_HASKELL="${var.latest_docker_image_amethyst}"
export TRAVIS_WORKER_DOCKER_IMAGE_JVM="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_DOCKER_IMAGE_NODE_JS="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_DOCKER_IMAGE_PERL="${var.latest_docker_image_amethyst}"
export TRAVIS_WORKER_DOCKER_IMAGE_PHP="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_DOCKER_IMAGE_PYTHON="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_DOCKER_IMAGE_RUBY="${var.latest_docker_image_garnet}"
export TRAVIS_WORKER_PRESTART_HOOK="/var/tmp/travis-run.d/travis-worker-prestart-hook"
export TRAVIS_WORKER_SELF_IMAGE="${var.latest_docker_image_worker}"
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    cloud_init_bash    = "${file("${path.module}/cloud-init.bash")}"
    cloud_init_env     = "${data.template_file.cloud_init_env.rendered}"
    prestart_hook_bash = "${file("${path.module}/prestart-hook.bash")}"
    worker_config      = "${data.template_file.worker_config_org.rendered}"
    worker_upstart     = "${file("${path.module}/../assets/travis-worker/travis-worker.conf")}"
    worker_wrapper     = "${file("${path.module}/../assets/travis-worker/travis-worker-wrapper")}"
  }
}

resource "packet_device" "worker-01" {
  hostname         = "worker-01"
  plan             = "baremetal_0"
  facility         = "ams1"
  operating_system = "ubuntu_14_04"
  billing_cycle    = "hourly"
  project_id       = "${var.packet_staging_1_project_id}"
  user_data        = "${data.template_file.cloud_config.rendered}"
}
