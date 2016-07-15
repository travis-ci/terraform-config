resource "aws_launch_configuration" "workers" {
    name_prefix = "${var.env}-workers-${var.site}-"
    image_id = "${var.aws_worker_ami}"
    instance_type = "c3.2xlarge"

    security_groups = ["${split(",", var.aws_security_groups)}"]

    user_data = "${var.cloud_init}"
    enable_monitoring = false

    key_name = "${var.bastion_key_name}"

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "workers" {
    name = "${var.env}-workers-${var.site}"

    vpc_zone_identifier = ["${split(",", var.aws_workers_subnets)}"]

    desired_capacity = 3

    max_size = 5
    min_size = 0
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
