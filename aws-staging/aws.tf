provider "aws" {}

resource "aws_vpc" "main" {
    cidr_block = "10.2.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.env_name}-main"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_launch_configuration" "workers" {
    name_prefix = "${var.env_name}-workers-"
    image_id = "${var.aws_worker_ami}"
    instance_type = "c3.2xlarge"
    security_groups = [
        "${module.aws_az_1b.workers_org_security_group_id}",
        "${module.aws_az_1e.workers_org_security_group_id}",
        "${module.aws_az_1b.workers_com_security_group_id}",
        "${module.aws_az_1e.workers_com_security_group_id}",
    ]
    user_data = "#include https://x:${var.pudding_token}@pudding-staging.herokuapp.com/init-scripts/${var.pudding_script_id}"
    enable_monitoring = false

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "workers" {
    name = "${var.env_name}-workers"
    vpc_zone_identifier = [
        "${module.aws_az_1b.workers_org_subnet_id}",
        "${module.aws_az_1e.workers_org_subnet_id}",
        "${module.aws_az_1b.workers_com_subnet_id}",
        "${module.aws_az_1e.workers_com_subnet_id}",
    ]
    max_size = 5
    min_size = 1
    desired_capacity = 1
    health_check_grace_period = 0
    health_check_type = "EC2"
    launch_configuration = "${aws_launch_configuration.workers.name}"

    tag {
        key = "env"
        value = "${var.env_name}"
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
}

resource "aws_autoscaling_policy" "workers_remove_capacity" {
    name = "${var.env_name}-workers-remove-capacity"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 3600
    autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_remove_capacity" {
    alarm_name = "${var.env_name}-workers-remove-capacity"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "v1.travis.rabbitmq.consumers.staging.builds.docker.headroom"
    namespace = "Travis/com-staging"
    period = "120"
    statistic = "Maximum"
    threshold = "8"
    alarm_actions = ["${aws_autoscaling_policy.workers_remove_capacity.arn}"]
}

resource "aws_autoscaling_policy" "workers_add_capacity" {
    name = "${var.env_name}-workers-add-capacity"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
}

resource "aws_cloudwatch_metric_alarm" "workers_add_capacity" {
    alarm_name = "${var.env_name}-workers-add-capacity"
    comparison_operator = "LessThanThreshold"
    evaluation_periods = "2"
    metric_name = "v1.travis.rabbitmq.consumers.staging.builds.docker.headroom"
    namespace = "Travis/com-staging"
    period = "120"
    statistic = "Maximum"
    threshold = "4"
    alarm_actions = ["${aws_autoscaling_policy.workers_add_capacity.arn}"]
}
