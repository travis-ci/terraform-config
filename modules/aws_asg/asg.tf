data "template_file" "worker_cloud_init" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    chef_json = "${var.worker_chef_json}"
    env = "${var.env}"
    site = "${var.site}"
    worker_config = "${var.worker_config}"
  }
}

resource "aws_launch_configuration" "workers" {
  name_prefix = "${var.env}-workers-${var.site}-"
  image_id = "${var.worker_ami}"
  instance_type = "c3.2xlarge"

  security_groups = ["${split(",", var.security_groups)}"]

  user_data = "${data.template_file.worker_cloud_init.rendered}"
  enable_monitoring = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "workers" {
  name = "${var.env}-workers-${var.site}"

  vpc_zone_identifier = ["${split(",", var.workers_subnets)}"]

  max_size = "${var.worker_asg_max_size}"
  min_size = "${var.worker_asg_min_size}"
  health_check_grace_period = 0
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.workers.name}"
  default_cooldown = 0

  tag {
    key = "Name"
    value = "${var.env}-worker-${var.site}-docker"
    propagate_at_launch = true
  }
  tag {
    key = "env"
    value = "${var.env}"
    propagate_at_launch = true
  }
  tag {
    key = "queue"
    value = "docker"
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
}

resource "aws_autoscaling_policy" "workers_remove_capacity" {
  name = "${var.env}-workers-${var.site}-remove-capacity"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_remove_capacity" {
  alarm_name = "${var.env}-workers-${var.site}-remove-capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "v1.travis.rabbitmq.consumers.${var.env}.builds.docker.headroom"
  namespace = "Travis/${var.site}-${var.env}"
  period = "120"
  statistic = "Maximum"
  threshold = "2"
  alarm_actions = ["${aws_autoscaling_policy.workers_remove_capacity.arn}"]
}

resource "aws_autoscaling_policy" "workers_add_capacity" {
  name = "${var.env}-workers-${var.site}-add-capacity"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_add_capacity" {
  alarm_name = "${var.env}-workers-${var.site}-add-capacity"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  metric_name = "v1.travis.rabbitmq.consumers.${var.env}.builds.docker.headroom"
  namespace = "Travis/${var.site}-${var.env}"
  period = "120"
  statistic = "Maximum"
  threshold = "2"
  alarm_actions = ["${aws_autoscaling_policy.workers_add_capacity.arn}"]
}
