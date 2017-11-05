variable "cyclist_auth_token" {}

variable "cyclist_aws_region" {
  default = "us-east-1"
}

variable "cyclist_debug" {
  default = "false"
}

variable "cyclist_redis_plan" {
  default = "premium-0"
}

variable "cyclist_scale" {
  default = "web=1:Standard-1X"
}

variable "cyclist_token_ttl" {
  default = "1h"
}

variable "cyclist_version" {
  default = "master"
}

variable "docker_storage_dm_basesize" {
  default = "12G"
}

variable "env" {}
variable "env_short" {}

variable "github_users" {
  default = ""
}

variable "heroku_org" {}
variable "index" {}

variable "lifecycle_hook_heartbeat_timeout" {
  default = 3600
}

variable "registry_hostname" {
  default = ""
}

variable "security_groups" {}
variable "site" {}
variable "syslog_address" {}
variable "worker_ami" {}

variable "worker_asg_max_size" {
  default = 5
}

variable "worker_asg_min_size" {
  default = 1
}

variable "worker_asg_namespace" {}

variable "worker_asg_scale_in_cooldown" {
  default = 300
}

variable "worker_asg_scale_in_evaluation_periods" {
  default = 2
}

variable "worker_asg_scale_in_period" {
  default = 60
}

variable "worker_asg_scale_in_qty" {
  default = -1
}

variable "worker_asg_scale_in_threshold" {
  default = 64
}

variable "worker_asg_scale_out_cooldown" {
  default = 300
}

variable "worker_asg_scale_out_evaluation_periods" {
  default = 2
}

variable "worker_asg_scale_out_period" {
  default = 60
}

variable "worker_asg_scale_out_qty" {
  default = 1
}

variable "worker_asg_scale_out_threshold" {
  default = 48
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
  default = "travisci/worker:v3.3.1"
}

variable "worker_instance_type" {
  default = "c3.2xlarge"
}

variable "worker_queue" {}
variable "worker_subnets" {}

data "template_file" "cloud_init_env" {
  template = <<EOF
export CYCLIST_AUTH_TOKEN="${var.cyclist_auth_token}"
export CYCLIST_URL="${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}"
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
export TRAVIS_WORKER_HEARTBEAT_URL="${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}/heartbeats/___INSTANCE_ID___"
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
  "debug": true
}
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets             = "${path.module}/../../assets"
    cloud_init_env     = "${data.template_file.cloud_init_env.rendered}"
    cyclist_url        = "${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}"
    docker_daemon_json = "${data.template_file.docker_daemon_json.rendered}"
    github_users_env   = "export GITHUB_USERS='${var.github_users}'"
    here               = "${path.module}"
    hostname_tmpl      = "___INSTANCE_ID___-${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}.travisci.net"
    registry_hostname  = "${var.registry_hostname}"
    syslog_address     = "${var.syslog_address}"
    worker_config      = "${var.worker_config}"
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
    content      = "${file("${path.module}/cloud-init.bash")}"
  }
}

resource "aws_launch_configuration" "workers" {
  name_prefix       = "${var.env}-${var.index}-workers-${var.site}-"
  image_id          = "${var.worker_ami}"
  instance_type     = "${var.worker_instance_type}"
  security_groups   = ["${split(",", var.security_groups)}"]
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
  name                      = "${var.env}-${var.index}-workers-${var.site}"
  default_cooldown          = 300
  health_check_grace_period = 0
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.workers.name}"
  max_size                  = "${var.worker_asg_max_size}"
  min_size                  = "${var.worker_asg_min_size}"
  vpc_zone_identifier       = ["${split(",", var.worker_subnets)}"]

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
    value               = "${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}"
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
}

resource "aws_autoscaling_policy" "workers_remove_capacity" {
  name                      = "${var.env}-${var.index}-workers-${var.site}-remove-capacity"
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  autoscaling_group_name    = "${aws_autoscaling_group.workers.name}"
  estimated_instance_warmup = "${var.worker_asg_scale_in_cooldown}"
  metric_aggregation_type   = "Maximum"

  # Headroom is just above scale-in threshold; remove n instances
  step_adjustment {
    scaling_adjustment          = "${var.worker_asg_scale_in_qty}"
    metric_interval_lower_bound = 1.0
    metric_interval_upper_bound = "${ceil(var.worker_asg_scale_in_threshold / 2)}"
  }

  # Headroom is way above scale-in threshold; remove n * 2 instances
  step_adjustment {
    scaling_adjustment          = "${var.worker_asg_scale_in_qty * 2}"
    metric_interval_lower_bound = "${ceil(var.worker_asg_scale_in_threshold / 2)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "workers_remove_capacity" {
  alarm_name          = "${var.env}-${var.index}-workers-${var.site}-remove-capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.worker_asg_scale_in_evaluation_periods}"
  metric_name         = "v1.travis.rabbitmq.consumers.${var.env}.builds.${var.worker_queue}.headroom"
  namespace           = "${var.worker_asg_namespace}"
  period              = "${var.worker_asg_scale_in_period}"
  statistic           = "Maximum"
  threshold           = "${var.worker_asg_scale_in_threshold}"
  alarm_actions       = ["${aws_autoscaling_policy.workers_remove_capacity.arn}"]
}

resource "aws_autoscaling_policy" "workers_add_capacity" {
  name                      = "${var.env}-${var.index}-workers-${var.site}-add-capacity"
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  autoscaling_group_name    = "${aws_autoscaling_group.workers.name}"
  estimated_instance_warmup = "${var.worker_asg_scale_out_cooldown}"
  metric_aggregation_type   = "Maximum"

  # Headroom is just below THRESHOLD, scale out normally
  step_adjustment {
    scaling_adjustment          = "${var.worker_asg_scale_out_qty}"
    metric_interval_lower_bound = "${floor(var.worker_asg_scale_out_threshold/-2.0)}"
  }

  # Headroom is less than half of THRESHOLD; scale out twice as much
  step_adjustment {
    scaling_adjustment          = "${var.worker_asg_scale_out_qty * 2}"
    metric_interval_upper_bound = "${floor(var.worker_asg_scale_out_threshold/-2.0)}"
    metric_interval_lower_bound = "${floor(var.worker_asg_scale_out_threshold/-1.0)}"
  }

  # Headroom is 0; scale out three times as much
  step_adjustment {
    scaling_adjustment          = "${var.worker_asg_scale_out_qty * 3}"
    metric_interval_upper_bound = "${floor(var.worker_asg_scale_out_threshold/-1.0)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "workers_add_capacity" {
  alarm_name          = "${var.env}-${var.index}-workers-${var.site}-add-capacity"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${var.worker_asg_scale_out_evaluation_periods}"
  metric_name         = "v1.travis.rabbitmq.consumers.${var.env}.builds.${var.worker_queue}.headroom"
  namespace           = "${var.worker_asg_namespace}"
  period              = "${var.worker_asg_scale_out_period}"
  statistic           = "Maximum"
  threshold           = "${var.worker_asg_scale_out_threshold}"
  alarm_actions       = ["${aws_autoscaling_policy.workers_add_capacity.arn}"]
}

resource "aws_sns_topic" "workers" {
  name = "${var.env}-${var.index}-workers-${var.site}"
}

resource "aws_sns_topic_subscription" "workers_cyclist" {
  topic_arn              = "${aws_sns_topic.workers.arn}"
  protocol               = "https"
  endpoint_auto_confirms = true
  endpoint               = "${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}/sns"
}

resource "aws_iam_user" "cyclist" {
  name = "cyclist-${var.env}-${var.index}-${var.site}"
}

resource "aws_iam_access_key" "cyclist" {
  user       = "${aws_iam_user.cyclist.name}"
  depends_on = ["aws_iam_user.cyclist"]
}

resource "aws_iam_user_policy" "cyclist_actions" {
  name = "cyclist_actions_${var.env}_${var.index}_${var.site}"
  user = "${aws_iam_user.cyclist.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sns:*",
        "autoscaling:*",
        "cloudwatch:PutMetricAlarm",
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

  depends_on = ["aws_iam_user.cyclist"]
}

resource "aws_iam_role" "workers_sns" {
  name = "${var.env}-${var.index}-workers-${var.site}-sns"

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
  name = "${var.env}-${var.index}-workers-${var.site}-sns"
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
  name                    = "${var.env}-${var.index}-workers-${var.site}-launching"
  autoscaling_group_name  = "${aws_autoscaling_group.workers.name}"
  default_result          = "CONTINUE"
  heartbeat_timeout       = "${var.lifecycle_hook_heartbeat_timeout}"
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn                = "${aws_iam_role.workers_sns.arn}"
}

resource "aws_autoscaling_lifecycle_hook" "workers_terminating" {
  name                    = "${var.env}-${var.index}-workers-${var.site}-terminating"
  autoscaling_group_name  = "${aws_autoscaling_group.workers.name}"
  default_result          = "CONTINUE"
  heartbeat_timeout       = "${var.lifecycle_hook_heartbeat_timeout}"
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn                = "${aws_iam_role.workers_sns.arn}"
}

resource "heroku_app" "cyclist" {
  name   = "cyclist-${replace(var.env, "precise-production", "precise-prod")}-${var.index}-${var.site}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    AWS_ACCESS_KEY      = "${aws_iam_access_key.cyclist.id}"
    AWS_REGION          = "${var.cyclist_aws_region}"
    AWS_SECRET_KEY      = "${aws_iam_access_key.cyclist.secret}"
    BUILDPACK_URL       = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    CYCLIST_AUTH_TOKENS = "${var.cyclist_auth_token}"
    CYCLIST_DEBUG       = "${var.cyclist_debug}"
    CYCLIST_TOKEN_TTL   = "${var.cyclist_token_ttl}"
    GO_IMPORT_PATH      = "github.com/travis-ci/cyclist"
  }
}

resource "heroku_drain" "cyclist_drain" {
  app = "${heroku_app.cyclist.name}"
  url = "syslog+tls://${var.syslog_address}"
}

resource "heroku_addon" "cyclist_redis" {
  app  = "${heroku_app.cyclist.name}"
  plan = "heroku-redis:${var.cyclist_redis_plan}"
}

resource "null_resource" "cyclist" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.cyclist.config_vars.0)))}"
    heroku_id        = "${heroku_app.cyclist.id}"
    ps_scale         = "${var.cyclist_scale}"
    version          = "${var.cyclist_version}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/heroku-wait-deploy-scale \
  travis-ci/cyclist \
  ${heroku_app.cyclist.id} \
  ${var.cyclist_scale} \
  ${var.cyclist_version}
EOF
  }
}

output "user_data" {
  value = "${data.template_file.cloud_config.rendered}"
}
