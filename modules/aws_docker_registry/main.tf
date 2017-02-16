variable "ami" {}

variable "azs" {
  default = "1b,1e"
}

variable "data_ebs_volume_size" {
  default = 5
}

variable "env" {}
variable "gateway_id" {}
variable "github_users" {}
variable "http_secret" {}
variable "index" {}

variable "instance_type" {
  default = "t2.small"
}

variable "subnets" {
  type = "list"
}

variable "travisci_net_external_zone_id" {}
variable "vpc_cidr" {}
variable "vpc_id" {}

resource "aws_security_group" "registry" {
  name   = "${var.env}-${var.index}-registry-${element(split(",", var.azs), count.index)}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.index}-registry-${element(split(",", var.azs), count.index)}"
  }

  count = "${length(split(",", var.azs))}"
}

resource "aws_s3_bucket" "registry_images" {
  acl    = "public-read"
  bucket = "travis-${var.env}-${var.index}-registry-images"
  region = "us-east-1"
}

resource "aws_iam_user" "registry" {
  name = "registry-${var.env}-${var.index}"
}

resource "aws_iam_access_key" "registry" {
  user = "${aws_iam_user.registry.name}"
}

resource "aws_iam_user_policy" "registry" {
  name = "registry-${var.env}-${var.index}-policy"
  user = "${aws_iam_user.registry.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "${aws_s3_bucket.registry_images.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "${aws_s3_bucket.registry_images.arn}/*"
    }
  ]
}
EOF
}

data "template_file" "registry_env" {
  template = <<EOF
REGISTRY_HTTP_ADDR=0.0.0.0:8000
REGISTRY_HTTP_SECRET=${var.http_secret}
REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
REGISTRY_STORAGE_S3_ACCESSKEY=${aws_iam_access_key.registry.id}
REGISTRY_STORAGE_S3_BUCKET=${aws_s3_bucket.registry_images.id}
REGISTRY_STORAGE_S3_OBJECTACL=public-read
REGISTRY_STORAGE_S3_REGION=us-east-1
REGISTRY_STORAGE_S3_SECRETKEY=${aws_iam_access_key.registry.secret}
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    registry_env     = "${data.template_file.registry_env.rendered}"
    cloud_init_bash  = "${file("${path.module}/cloud-init.bash")}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    hostname_tmpl    = "___INSTANCE_ID___-registry-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  }
}

resource "aws_launch_configuration" "registry" {
  name_prefix       = "${var.env}-${var.index}-registry-"
  image_id          = "${var.ami}"
  instance_type     = "${var.instance_type}"
  security_groups   = ["${aws_security_group.registry.*.id}"]
  user_data         = "${data.template_file.cloud_config.rendered}"
  enable_monitoring = false

  ebs_block_device {
    device_name = "xvdc"
    volume_size = "${var.data_ebs_volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "registry" {
  name            = "registry-elb-${var.env}-${var.index}"
  subnets         = ["${var.subnets}"]
  security_groups = ["${aws_security_group.registry.*.id}"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 9
    target              = "HTTP:8000/v2/"
    interval            = 10
    timeout             = 5
  }

  internal = true

  tags {
    Name = "registry-elb-${var.env}-${var.index}"
  }
}

resource "aws_autoscaling_group" "registry" {
  name                      = "registry-${var.env}-${var.index}-asg"
  max_size                  = 2
  min_size                  = 2
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.registry.name}"
  load_balancers            = ["${aws_elb.registry.name}"]
  vpc_zone_identifier       = ["${var.subnets}"]
  force_delete              = true
  metrics_granularity       = "1Minute"
  wait_for_capacity_timeout = "10m"

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.index}-registry-asg"
    propagate_at_launch = false
  }
}

resource "aws_route53_record" "registry" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "registry-${var.env}-${var.index}.aws-us-east-1.travisci.net"
  type    = "A"

  alias {
    name                   = "${aws_elb.registry.dns_name}"
    zone_id                = "${aws_elb.registry.zone_id}"
    evaluate_target_health = false
  }
}

output "hostname" {
  value = "${aws_route53_record.registry.name}"
}
