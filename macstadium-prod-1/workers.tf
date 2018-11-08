variable "latest_travis_worker_version" {}

variable "travis_worker_version" {
  default = "v4.4.0"
}

variable "worker_org_pool_size" {
  default = 39
}

variable "worker_com_pool_size" {
  default = 26
}

resource "random_id" "travis_worker_production_org_token" {
  byte_length = 32
}

resource "random_id" "travis_worker_production_com_token" {
  byte_length = 32
}

module "aws_iam_user_s3_com" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-macstadium-production-${var.index}-com"
  s3_bucket_name = "build-trace.travis-ci.com"
}

module "aws_iam_user_s3_org" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-macstadium-production-${var.index}-org"
  s3_bucket_name = "build-trace.travis-ci.org"
}

data "template_file" "worker_config_common" {
  template = <<EOF
export TRAVIS_WORKER_AMQP_HEARTBEAT="60s"
export TRAVIS_WORKER_BUILD_FIX_ETC_HOSTS="true"
export TRAVIS_WORKER_BUILD_FIX_RESOLV_CONF="true"
export TRAVIS_WORKER_BUILD_PARANOID="false"
export TRAVIS_WORKER_BUILD_TRACE_ENABLED=true
export TRAVIS_WORKER_BUILD_TRACE_S3_KEY_PREFIX=trace/
export TRAVIS_WORKER_BUILD_TRACE_S3_REGION=us-east-1
export TRAVIS_WORKER_INFRA="macstadium"
export TRAVIS_WORKER_QUEUE_TYPE="amqp"
export TRAVIS_WORKER_QUEUE_NAME="builds.macstadium6"
export TRAVIS_WORKER_PROVIDER_NAME="jupiterbrain"
export TRAVIS_WORKER_JUPITERBRAIN_IMAGE_SELECTOR_TYPE="api"
export TRAVIS_WORKER_JUPITERBRAIN_SSH_KEY_PATH="/etc/travis-vm-ssh-key"
export TRAVIS_WORKER_STARTUP_TIMEOUT="8m"
export TRAVIS_WORKER_SCRIPT_UPLOAD_TIMEOUT="6m"
export TRAVIS_WORKER_RABBITMQ_SHARDING="true"
EOF
}

module "worker_production_org_1" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-org-1"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_org_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7070"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_org_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_org_token.hex}@127.0.0.1:8081/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-org-macstadium-${var.index}-1-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_production_org_2" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-org-2"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_org_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7071"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_org_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_org_token.hex}@127.0.0.1:8081/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-org-macstadium-${var.index}-2-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_production_org_3" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-org-3"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_org_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7072"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_org_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_org_token.hex}@127.0.0.1:8081/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-org-macstadium-${var.index}-3-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_production_org_4" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-org-4"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="20"
export TRAVIS_WORKER_PPROF_PORT="7073"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_org_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_org_token.hex}@127.0.0.1:8081/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-org-macstadium-${var.index}-4-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_production_com_1" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-com-1"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_com_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7080"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_com_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_com_token.hex}@127.0.0.1:8083/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-com-macstadium-${var.index}-1-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_production_com_2" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-com-2"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_com_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7081"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_com_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_com_token.hex}@127.0.0.1:8083/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-com-macstadium-${var.index}-2-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_production_com_3" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-com-3"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_com_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7082"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_com_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_com_token.hex}@127.0.0.1:8083/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-com-macstadium-${var.index}-3-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_production_com_4" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "production-com-4"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="${var.worker_com_pool_size}"
export TRAVIS_WORKER_PPROF_PORT="7083"
export TRAVIS_WORKER_HTTP_API_AUTH="macstadium-worker:${random_id.travis_worker_production_com_token.hex}"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_production_com_token.hex}@127.0.0.1:8083/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-production-com-macstadium-${var.index}-4-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_custom_1" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "custom-1"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="5"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_custom_1_token.hex}@127.0.0.1:8085/"
export TRAVIS_WORKER_QUEUE_NAME="builds.customer.${lower(var.custom_1_name)}-macos"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-custom-1-${var.index}-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_custom_2" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "custom-2"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="5"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_custom_2_token.hex}@127.0.0.1:8086/"
export TRAVIS_WORKER_QUEUE_NAME="builds.customer.${lower(var.custom_2_name)}-macos"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-custom-2-${var.index}-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_custom_4" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "custom-4"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="5"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_custom_4_token.hex}@127.0.0.1:8088/"
export TRAVIS_WORKER_QUEUE_NAME="builds.customer.${lower(var.custom_4_name)}"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-custom-4-${var.index}-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_custom_5" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "custom-5"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="5"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_custom_5_token.hex}@127.0.0.1:8089/"
export TRAVIS_WORKER_QUEUE_NAME="builds.customer.${lower(var.custom_5_name)}"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-custom-5-${var.index}-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_custom_6" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "custom-6"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-production-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="5"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_custom_6_token.hex}@127.0.0.1:8091/"
export TRAVIS_WORKER_QUEUE_NAME="builds.customer.${lower(var.custom_6_name)}"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-custom-6-${var.index}-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}
