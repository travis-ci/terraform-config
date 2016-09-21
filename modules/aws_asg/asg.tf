data "template_file" "worker_cloud_init" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    cyclist_auth_token = "${element(split(",", var.cyclist_auth_tokens), var.index - 1)}"
    cyclist_url = "${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}"
    env = "${var.env}"
    index = "${var.index}"
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
  name_prefix = "${var.env}-workers-${var.site}-${var.index}-"
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
  name = "${var.env}-workers-${var.site}-${var.index}"

  vpc_zone_identifier = ["${split(",", var.worker_subnets)}"]

  max_size = "${var.worker_asg_max_size}"
  min_size = "${var.worker_asg_min_size}"
  health_check_grace_period = 0
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.workers.name}"
  default_cooldown = 0

  tag {
    key = "Name"
    value = "${var.env}-worker-${var.site}-${var.index}-ec2"
    propagate_at_launch = true
  }
  tag {
    key = "env"
    value = "${var.env}"
    propagate_at_launch = true
  }
  tag {
    key = "queue"
    value = "ec2"
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
  name = "${var.env}-workers-${var.site}-${var.index}-remove-capacity"
  scaling_adjustment = "${var.worker_asg_scale_in_qty}"
  adjustment_type = "ChangeInCapacity"
  cooldown = "${var.worker_asg_scale_in_cooldown}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_remove_capacity" {
  alarm_name = "${var.env}-workers-${var.site}-${var.index}-remove-capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "v1.travis.rabbitmq.consumers.${var.env}.builds.ec2.headroom"
  namespace = "${var.worker_asg_namespace}"
  period = 60
  statistic = "Maximum"
  threshold = "${var.worker_asg_scale_in_threshold}"
  alarm_actions = ["${aws_autoscaling_policy.workers_remove_capacity.arn}"]
}

resource "aws_autoscaling_policy" "workers_add_capacity" {
  name = "${var.env}-workers-${var.site}-${var.index}-add-capacity"
  scaling_adjustment = "${var.worker_asg_scale_out_qty}"
  adjustment_type = "ChangeInCapacity"
  cooldown = "${var.worker_asg_scale_out_cooldown}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_add_capacity" {
  alarm_name = "${var.env}-workers-${var.site}-${var.index}-add-capacity"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 2
  metric_name = "v1.travis.rabbitmq.consumers.${var.env}.builds.ec2.headroom"
  namespace = "${var.worker_asg_namespace}"
  period = 60
  statistic = "Maximum"
  threshold = "${var.worker_asg_scale_out_threshold}"
  alarm_actions = ["${aws_autoscaling_policy.workers_add_capacity.arn}"]
}
