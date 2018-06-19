variable "cyclist_url" {}
variable "cyclist_auth_token" {}

variable "docker_storage_dm_basesize" {
  default = "12G"
}

variable "env" {}

variable "github_users" {
  default = ""
}

variable "index" {}

variable "lifecycle_hook_heartbeat_timeout" {
  default = 3600
}

variable "registry_hostname" {
  default = ""
}

variable "security_groups" {
  type = "list"
}

variable "site" {}
variable "syslog_address" {}
variable "worker_ami" {}

variable "worker_asg_max_size" {
  default = 5
}

variable "worker_asg_min_size" {
  default = 1
}

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

variable "worker_instance_type" {
  default = "c3.2xlarge"
}

variable "worker_queue" {}

variable "worker_subnets" {
  type = "list"
}

data "template_file" "cloud_init_env" {
  template = <<EOF
export CYCLIST_AUTH_TOKEN="${var.cyclist_auth_token}"
export CYCLIST_URL="${var.cyclist_url}"
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
export TRAVIS_WORKER_HEARTBEAT_URL="${var.cyclist_url}/heartbeats/___INSTANCE_ID___"
export TRAVIS_WORKER_HEARTBEAT_URL_AUTH_TOKEN="file:///var/tmp/travis-run.d/instance-token"
export TRAVIS_WORKER_PRESTART_HOOK="/var/tmp/travis-run.d/travis-worker-prestart-hook"
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
export TRAVIS_WORKER_START_HOOK="/var/tmp/travis-run.d/travis-worker-start-hook"
export TRAVIS_WORKER_STOP_HOOK="/var/tmp/travis-run.d/travis-worker-stop-hook"
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
  "insecure-registries": [
    "10.0.0.0/8"
  ],
  ${var.registry_hostname != "" ?
    "\"registry-mirrors\": [\"http://${var.registry_hostname}\"]," : ""}
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.basesize=${var.docker_storage_dm_basesize}",
    "dm.datadev=/dev/direct-lvm/data",
    "dm.metadatadev=/dev/direct-lvm/metadata",
    "dm.fs=xfs"
  ],
  "userns-remap": "default",
  "debug": false
}
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/../aws_asg/cloud-config.yml.tpl")}"

  vars {
    assets             = "${path.module}/../../assets"
    cloud_init_env     = "${data.template_file.cloud_init_env.rendered}"
    cyclist_url        = "${var.cyclist_url}"
    docker_daemon_json = "${data.template_file.docker_daemon_json.rendered}"
    here               = "${path.module}/../aws_asg"
    hostname_tmpl      = "___INSTANCE_ID___-${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}-canary.travisci.net"
    registry_hostname  = "${var.registry_hostname}"
    syslog_address     = "${var.syslog_address}"
    worker_config      = "${var.worker_config}"

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

data "template_cloudinit_config" "cloud_config" {
  part {
    filename     = "cloud-config"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
  }

  part {
    filename     = "cloud-init"
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/../aws_asg/cloud-init.bash")}"
  }
}

resource "aws_launch_configuration" "workers" {
  name_prefix       = "${var.env}-${var.index}-workers-${var.site}-canary-"
  image_id          = "${var.worker_ami}"
  instance_type     = "${var.worker_instance_type}"
  key_name          = "aj"
  security_groups   = ["${var.security_groups}"]
  user_data         = "${data.template_cloudinit_config.cloud_config.rendered}"
  enable_monitoring = true

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-worker-verify-config \
  "${base64encode(data.template_file.cloud_config.rendered)}"
EOF
  }
}

resource "aws_autoscaling_group" "workers" {
  name                      = "${var.env}-${var.index}-workers-${var.site}-canary"
  default_cooldown          = 300
  health_check_grace_period = 0
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.workers.name}"
  max_size                  = "${var.worker_asg_max_size}"
  min_size                  = "${var.worker_asg_min_size}"
  vpc_zone_identifier       = ["${var.worker_subnets}"]

  termination_policies = [
    "OldestLaunchConfiguration",
    "OldestInstance",
    "Default",
  ]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}-canary"
    propagate_at_launch = true
  }

  tag {
    key                 = "env"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "queue"
    value               = "${var.worker_queue}"
    propagate_at_launch = true
  }

  tag {
    key                 = "role"
    value               = "worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "site"
    value               = "${var.site}"
    propagate_at_launch = true
  }

  tag {
    key                 = "index"
    value               = "${var.index}"
    propagate_at_launch = true
  }

  tag {
    key                 = "canary"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_sns_topic" "workers" {
  name = "${var.env}-${var.index}-workers-${var.site}-canary"
}

resource "aws_sns_topic_subscription" "workers_cyclist" {
  topic_arn              = "${aws_sns_topic.workers.arn}"
  protocol               = "https"
  endpoint_auto_confirms = true
  endpoint               = "${var.cyclist_url}/sns"
}

resource "aws_iam_role" "workers_sns" {
  name = "${var.env}-${var.index}-workers-${var.site}-canary-sns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "workers_sns" {
  name = "${var.env}-${var.index}-workers-${var.site}-canary-sns"
  role = "${aws_iam_role.workers_sns.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:SendMessage",
        "sqs:GetQueueUrl",
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_autoscaling_lifecycle_hook" "workers_launching" {
  name                    = "${var.env}-${var.index}-workers-${var.site}-canary-launching"
  autoscaling_group_name  = "${aws_autoscaling_group.workers.name}"
  default_result          = "CONTINUE"
  heartbeat_timeout       = "${var.lifecycle_hook_heartbeat_timeout}"
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn                = "${aws_iam_role.workers_sns.arn}"
}

resource "aws_autoscaling_lifecycle_hook" "workers_terminating" {
  name                    = "${var.env}-${var.index}-workers-${var.site}-canary-terminating"
  autoscaling_group_name  = "${aws_autoscaling_group.workers.name}"
  default_result          = "CONTINUE"
  heartbeat_timeout       = "${var.lifecycle_hook_heartbeat_timeout}"
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn                = "${aws_iam_role.workers_sns.arn}"
}

output "user_data" {
  value = "${data.template_file.cloud_config.rendered}"
}
