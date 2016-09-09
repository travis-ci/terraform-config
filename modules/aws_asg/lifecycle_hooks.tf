resource "aws_sns_topic" "workers" {
  name = "${var.env}-workers-${var.site}"
}

resource "aws_sns_topic_subscription" "workers_pudding" {
  topic_arn = "${aws_sns_topic.workers.arn}"
  protocol = "${var.sns_subscription_protocol}"
  endpoint_auto_confirms = true
  endpoint = "${var.sns_subscription_endpoint}"
}

resource "aws_iam_role" "workers_sns" {
  name = "${var.env}-workers-${var.site}-sns"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "workers_sns" {
  name = "${var.env}-workers-${var.site}-sns"
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

# FIXME: once cyclist is up?
# resource "aws_autoscaling_lifecycle_hook" "workers_launching" {
#   name = "${var.env}-workers-${var.site}-launching"
#   autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
#   default_result = "CONTINUE"
#   heartbeat_timeout = 900
#   lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
#   notification_target_arn = "${aws_sns_topic.workers.arn}"
#   role_arn = "${aws_iam_role.workers_sns.arn}"
# }
#
# resource "aws_autoscaling_lifecycle_hook" "workers_terminating" {
#   name = "${var.env}-workers-${var.site}-terminating"
#   autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
#   default_result = "CONTINUE"
#   heartbeat_timeout = 900
#   lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
#   notification_target_arn = "${aws_sns_topic.workers.arn}"
#   role_arn = "${aws_iam_role.workers_sns.arn}"
# }
