resource "aws_sns_topic" "workers" {
  name = "${var.env}-workers"
}

resource "aws_sns_topic_subscription" "workers_pudding" {
    topic_arn = "${aws_sns_topic.workers.arn}"
    protocol = "https"
    endpoint_auto_confirms = true
    endpoint = "https://pudding-staging.herokuapp.com/sns-messages"
}

resource "aws_iam_role" "workers_sns" {
    name = "${var.env}-workers-sns-4"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

/*
resource "aws_iam_role_policy" "workers_sns" {
    name = "${var.env}-workers-sns"
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
*/

/*
resource "aws_autoscaling_lifecycle_hook" "workers_launching" {
    name = "${var.env}-workers-launching"
    autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
    default_result = "CONTINUE"
    heartbeat_timeout = 900
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_target_arn = "${aws_sns_topic.workers.arn}"
    role_arn = "${aws_iam_role.workers_sns.arn}"
}

resource "aws_autoscaling_lifecycle_hook" "workers_terminating" {
    name = "${var.env}-workers-terminating"
    autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
    default_result = "CONTINUE"
    heartbeat_timeout = 900
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = "${aws_sns_topic.workers.arn}"
    role_arn = "${aws_iam_role.workers_sns.arn}"
}
*/
