module "aws_az_1b" {
    source = "../modules/aws_az"

    env_name = "${var.env_name}"
    aws_az = "1b"
    aws_public_subnet = "10.2.1.0/24"
    aws_workers_subnet = "10.2.2.0/24"
    aws_vpc_id = "${aws_vpc.main.id}"
    aws_gateway_id = "${aws_internet_gateway.gw.id}"

    aws_bastion_ami = "${var.aws_bastion_ami}"
    aws_worker_ami = "${var.aws_worker_ami}"
    aws_nat_ami = "${var.aws_nat_ami}"
}

module "aws_az_1e" {
    source = "../modules/aws_az"

    env_name = "${var.env_name}"
    aws_az = "1e"
    aws_public_subnet = "10.2.3.0/24"
    aws_workers_subnet = "10.2.4.0/24"
    aws_vpc_id = "${aws_vpc.main.id}"
    aws_gateway_id = "${aws_internet_gateway.gw.id}"

    aws_bastion_ami = "${var.aws_bastion_ami}"
    aws_worker_ami = "${var.aws_worker_ami}"
    aws_nat_ami = "${var.aws_nat_ami}"
}

resource "aws_launch_configuration" "workers" {
    name_prefix = "${var.env_name}-workers-"
    image_id = "${var.aws_worker_ami}"
    instance_type = "c3.2xlarge"
    security_groups = [
        "${module.aws_az_1b.workers_security_group_id}",
        "${module.aws_az_1e.workers_security_group_id}",
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
        "${module.aws_az_1b.workers_subnet_id}",
        "${module.aws_az_1e.workers_subnet_id}",
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
