resource "aws_sns_topic" "workers" {
  name = "${var.env}-workers-${var.site}-${var.index}"
}

resource "aws_sns_topic_subscription" "workers_cyclist" {
  topic_arn = "${aws_sns_topic.workers.arn}"
  protocol = "https"
  endpoint_auto_confirms = true
  endpoint = "${heroku_app.cyclist.web_url}/sns"
}

resource "aws_iam_user" "cyclist" {
  name = "cyclist-${var.site}-${var.env}-${var.index}"
}

resource "aws_iam_access_key" "cyclist" {
  user = "${aws_iam_user.cyclist.name}"
}

resource "aws_iam_user_policy" "cyclist_actions" {
  name = "cyclist_actions_${var.site}_${var.env}_${var.index}"
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
}

resource "aws_iam_role" "workers_sns" {
  name = "${var.env}-workers-${var.site}-${var.index}-sns"
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
  name = "${var.env}-workers-${var.site}-${var.index}-sns"
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
  name = "${var.env}-workers-${var.site}-${var.index}-launching"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  default_result = "CONTINUE"
  heartbeat_timeout = 900
  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn = "${aws_iam_role.workers_sns.arn}"
}

resource "aws_autoscaling_lifecycle_hook" "workers_terminating" {
  name = "${var.env}-workers-${var.site}-${var.index}-terminating"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  default_result = "CONTINUE"
  heartbeat_timeout = 900
  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = "${aws_sns_topic.workers.arn}"
  role_arn = "${aws_iam_role.workers_sns.arn}"
}
