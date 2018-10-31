variable "travis_worker_version" {
  default = "v4.6.0"
}

module "aws_iam_user_s3_com" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-macstadium-staging-${var.index}-com"
  s3_bucket_name = "build-trace-staging.travis-ci.com"
}

module "aws_iam_user_s3_org" {
  source         = "../modules/aws_iam_user_s3"
  iam_user_name  = "worker-macstadium-staging-${var.index}-org"
  s3_bucket_name = "build-trace-staging.travis-ci.org"
}

data "template_file" "worker_config_common" {
  template = <<EOF
export TRAVIS_WORKER_AMQP_HEARTBEAT="60s"
export TRAVIS_WORKER_BUILD_FIX_ETC_HOSTS="true"
export TRAVIS_WORKER_BUILD_FIX_RESOLV_CONF="true"
export TRAVIS_WORKER_BUILD_PARANOID="false"
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

module "worker_staging_org_1" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-org-1"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_org_token.hex}@127.0.0.1:8082/"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-staging-org-${var.index}-1-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_staging_org_2" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-org-2"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_org_token.hex}@127.0.0.1:8082/"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-staging-org-${var.index}-2-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_staging_org_3" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-org-3"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_org_token.hex}@127.0.0.1:8082/"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-staging-org-${var.index}-3-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_staging_org_4" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-org-4"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-org-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_TRAVIS_SITE="org"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_org_token.hex}@127.0.0.1:8082/"
export TRAVIS_WORKER_LIBRATO_SOURCE="worker-staging-org-${var.index}-4-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_org.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_org.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_org.secret}
EOF
}

module "worker_staging_com_1" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-com-1"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_com_token.hex}@127.0.0.1:8084/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-staging-com-macstadium-${var.index}-1-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_staging_com_2" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-com-2"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_com_token.hex}@127.0.0.1:8084/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-staging-com-macstadium-${var.index}-2-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_staging_com_3" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-com-3"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_com_token.hex}@127.0.0.1:8084/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-staging-com-macstadium-${var.index}-3-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_staging_com_4" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-com-4"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_com_token.hex}@127.0.0.1:8084/"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-staging-com-macstadium-${var.index}-4-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_staging_com_free_1" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-com-free-1"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_com_token.hex}@127.0.0.1:8084/"
export TRAVIS_WORKER_QUEUE_NAME="builds.macstadium6-free"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-staging-com-free-macstadium-${var.index}-1-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}

module "worker_staging_com_free_2" {
  source             = "../modules/macstadium_go_worker"
  host_id            = "${module.macstadium_infrastructure_staging.wjb_uuid}"
  ssh_host           = "${module.macstadium_infrastructure_staging.wjb_ip}"
  ssh_user           = "${var.ssh_user}"
  worker_version     = "${var.travis_worker_version}"
  env                = "staging-com-free-2"
  index              = "${var.index}"
  worker_base_config = "${data.template_file.worker_config_common.rendered}"
  worker_env_config  = "${file("${path.module}/config/travis-worker-staging-com-common")}"

  worker_local_config = <<EOF
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE="com"
export TRAVIS_WORKER_POOL_SIZE="2"
export TRAVIS_WORKER_JUPITERBRAIN_ENDPOINT="http://${random_id.jupiter_brain_staging_com_token.hex}@127.0.0.1:8084/"
export TRAVIS_WORKER_QUEUE_NAME="builds.macstadium6-free"
export TRAVIS_WORKER_LIBRATO_SOURCE="travis-worker-staging-com-free-macstadium-${var.index}-2-dc18"

export TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET=${module.aws_iam_user_s3_com.bucket}
export AWS_ACCESS_KEY_ID=${module.aws_iam_user_s3_com.id}
export AWS_SECRET_ACCESS_KEY=${module.aws_iam_user_s3_com.secret}
EOF
}
