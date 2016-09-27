variable "cyclist_auth_tokens" {}
variable "cyclist_aws_region" { default = "us-east-1" }
variable "cyclist_debug" { default = "false" }
variable "cyclist_redis_plan" { default = "premium-0" }
variable "cyclist_scale" { default = "web=1:Standard-1X" }
variable "cyclist_version" { default = "master" }
variable "env" {}
variable "env_short" {}
variable "heroku_org" {}
variable "index" {}
variable "security_groups" {}
variable "site" {}
variable "syslog_address" {}
variable "worker_ami" {}
variable "worker_asg_max_size" { default = 5 }
variable "worker_asg_min_size" { default = 1 }
variable "worker_asg_namespace" {}
variable "worker_asg_scale_in_cooldown" { default = 300 }
variable "worker_asg_scale_in_qty" { default = -1 }
variable "worker_asg_scale_in_threshold" { default = "64.0" }
variable "worker_asg_scale_out_cooldown" { default = 300 }
variable "worker_asg_scale_out_qty" { default = 1 }
variable "worker_asg_scale_out_threshold" { default = "48.0" }
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
variable "worker_docker_self_image" { default = "quay.io/travisci/worker:v2.4.0" }
variable "worker_instance_type" { default = "c3.2xlarge" }
variable "worker_queue" {}
variable "worker_subnets" {}

data "template_file" "worker_cloud_init" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    cyclist_auth_token = "${element(split(",", var.cyclist_auth_tokens), var.index)}"
    cyclist_url = "${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}"
    env = "${var.env}"
    index = "${var.index}"
    queue = "${var.worker_queue}"
    site = "${var.site}"
    syslog_address = "${var.syslog_address}"
    syslog_host = "${element(split(":", var.syslog_address), 0)}"
    worker_config = "${var.worker_config}"
    worker_docker_image_android = "${var.worker_docker_image_android}"
    worker_docker_image_default = "${var.worker_docker_image_default}"
    worker_docker_image_erlang = "${var.worker_docker_image_erlang}"
    worker_docker_image_go = "${var.worker_docker_image_go}"
    worker_docker_image_haskell = "${var.worker_docker_image_haskell}"
    worker_docker_image_jvm = "${var.worker_docker_image_jvm}"
    worker_docker_image_node_js = "${var.worker_docker_image_node_js}"
    worker_docker_image_perl = "${var.worker_docker_image_perl}"
    worker_docker_image_php = "${var.worker_docker_image_php}"
    worker_docker_image_python = "${var.worker_docker_image_python}"
    worker_docker_image_ruby = "${var.worker_docker_image_ruby}"
    worker_docker_self_image = "${var.worker_docker_self_image}"
  }
}

resource "aws_launch_configuration" "workers" {
  name_prefix = "${var.env}-${var.index}-workers-${var.site}-"
  image_id = "${var.worker_ami}"
  instance_type = "${var.worker_instance_type}"

  security_groups = ["${split(",", var.security_groups)}"]

  user_data = "${data.template_file.worker_cloud_init.rendered}"
  enable_monitoring = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "workers" {
  name = "${var.env}-${var.index}-workers-${var.site}"
  default_cooldown = 300
  health_check_grace_period = 0
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.workers.name}"
  max_size = "${var.worker_asg_max_size}"
  min_size = "${var.worker_asg_min_size}"
  vpc_zone_identifier = ["${split(",", var.worker_subnets)}"]
  termination_policies = [
    "OldestLaunchConfiguration",
    "OldestInstance",
    "Default"
  ]

  tag {
    key = "Name"
    value = "${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}"
    propagate_at_launch = true
  }
  tag {
    key = "env"
    value = "${var.env}"
    propagate_at_launch = true
  }
  tag {
    key = "queue"
    value = "${var.worker_queue}"
    propagate_at_launch = true
  }
  tag {
    key = "role"
    value = "worker"
    propagate_at_launch = true
  }
  tag {
    key = "site"
    value = "${var.site}"
    propagate_at_launch = true
  }
  tag {
    key = "index"
    value = "${var.index}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "workers_remove_capacity" {
  name = "${var.env}-${var.index}-workers-${var.site}-remove-capacity"
  scaling_adjustment = "${var.worker_asg_scale_in_qty}"
  adjustment_type = "ChangeInCapacity"
  cooldown = "${var.worker_asg_scale_in_cooldown}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_remove_capacity" {
  alarm_name = "${var.env}-${var.index}-workers-${var.site}-remove-capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "v1.travis.rabbitmq.consumers.${var.env_short}.builds.${var.worker_queue}.headroom"
  namespace = "${var.worker_asg_namespace}"
  period = 60
  statistic = "Maximum"
  threshold = "${var.worker_asg_scale_in_threshold}"
  alarm_actions = ["${aws_autoscaling_policy.workers_remove_capacity.arn}"]
}

resource "aws_autoscaling_policy" "workers_add_capacity" {
  name = "${var.env}-${var.index}-workers-${var.site}-add-capacity"
  scaling_adjustment = "${var.worker_asg_scale_out_qty}"
  adjustment_type = "ChangeInCapacity"
  cooldown = "${var.worker_asg_scale_out_cooldown}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_add_capacity" {
  alarm_name = "${var.env}-${var.index}-workers-${var.site}-add-capacity"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 2
  metric_name = "v1.travis.rabbitmq.consumers.${var.env_short}.builds.${var.worker_queue}.headroom"
  namespace = "${var.worker_asg_namespace}"
  period = 60
  statistic = "Maximum"
  threshold = "${var.worker_asg_scale_out_threshold}"
  alarm_actions = ["${aws_autoscaling_policy.workers_add_capacity.arn}"]
}

resource "aws_sns_topic" "workers" {
  name = "${var.env}-${var.index}-workers-${var.site}"
}

resource "aws_sns_topic_subscription" "workers_cyclist" {
  topic_arn = "${aws_sns_topic.workers.arn}"
  protocol = "https"
  endpoint_auto_confirms = true
  endpoint = "${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}/sns"
}

resource "aws_iam_user" "cyclist" {
  name = "cyclist-${var.env}-${var.index}-${var.site}"
}

resource "aws_iam_access_key" "cyclist" {
  user = "${aws_iam_user.cyclist.name}"
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
        "SNS:*",
        "autoscaling:*",
        "cloudwatch:PutMetricAlarm",
        "iam:PassRole"
      ],
      "Resource": "*",
      "Effect": "Allow"
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
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
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
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:GetQueueUrl",
        "sns:Publish"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_autoscaling_lifecycle_hook" "workers_launching" {
  name = "${var.env}-${var.index}-workers-${var.site}-launching"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  default_result = "CONTINUE"
  heartbeat_timeout = 900
  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn = "${aws_iam_role.workers_sns.arn}"
}

resource "aws_autoscaling_lifecycle_hook" "workers_terminating" {
  name = "${var.env}-${var.index}-workers-${var.site}-terminating"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  default_result = "CONTINUE"
  heartbeat_timeout = 900
  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn = "${aws_iam_role.workers_sns.arn}"
}

resource "heroku_app" "cyclist" {
  name = "cyclist-${var.env}-${var.index}-${var.site}"
  region = "us"
  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    AWS_ACCESS_KEY = "${aws_iam_access_key.cyclist.id}"
    AWS_REGION = "${var.cyclist_aws_region}"
    AWS_SECRET_KEY = "${aws_iam_access_key.cyclist.secret}"
    BUILDPACK_URL = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    CYCLIST_AUTH_TOKENS = "${var.cyclist_auth_tokens}"
    CYCLIST_DEBUG = "${var.cyclist_debug}"
    GO_IMPORT_PATH = "github.com/travis-ci/cyclist"
  }
}

resource "heroku_drain" "cyclist_drain" {
  app = "${heroku_app.cyclist.name}"
  url = "syslog+tls://${var.syslog_address}"
}

resource "heroku_addon" "cyclist_redis" {
  app = "${heroku_app.cyclist.name}"
  plan = "heroku-redis:${var.cyclist_redis_plan}"
}

resource "null_resource" "cyclist" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.cyclist.config_vars.0)))}"
    heroku_id = "${heroku_app.cyclist.id}"
    ps_scale = "${var.cyclist_scale}"
    version = "${var.cyclist_version}"
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
