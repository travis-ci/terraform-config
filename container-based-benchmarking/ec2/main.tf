variable "docker_storage_dm_basesize" {
  default = "12G"
}

variable "github_users" {
  default = "emma:emdantrim dan:meatballhat"
}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.4.0"
}

data "template_file" "cloud_init_env" {
  template = <<EOF
export TRAVIS_WORKER_DOCKER_IMAGE_ANDROID=""
export TRAVIS_WORKER_DOCKER_IMAGE_DEFAULT=""
export TRAVIS_WORKER_DOCKER_IMAGE_ERLANG=""
export TRAVIS_WORKER_DOCKER_IMAGE_GO=""
export TRAVIS_WORKER_DOCKER_IMAGE_HASKELL=""
export TRAVIS_WORKER_DOCKER_IMAGE_JVM=""
export TRAVIS_WORKER_DOCKER_IMAGE_NODE_JS=""
export TRAVIS_WORKER_DOCKER_IMAGE_PERL=""
export TRAVIS_WORKER_DOCKER_IMAGE_PHP=""
export TRAVIS_WORKER_DOCKER_IMAGE_PYTHON=""
export TRAVIS_WORKER_DOCKER_IMAGE_RUBY=""
export TRAVIS_WORKER_PRESTART_HOOK="/var/tmp/travis-run.d/travis-worker-prestart-hook"
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "docker_daemon_json" {
  template = <<EOF
{
  "data-root": "/mnt/docker",
  "hosts": [
    "tcp://127.0.0.1:4243",
    "unix:///var/run/docker.sock"
  ],
  "icc": false,
  "insecure-registries": [
    "10.0.0.0/8"
  ],
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.basesize=${var.docker_storage_dm_basesize}",
    "dm.datadev=/dev/direct-lvm/data",
    "dm.metadatadev=/dev/direct-lvm/metadata",
    "dm.fs=xfs"
  ],
  "userns-remap": "default",
  "debug": true
}
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets             = "${path.module}/../../assets"
    cloud_init_env     = "${data.template_file.cloud_init_env.rendered}"
    docker_daemon_json = "${data.template_file.docker_daemon_json.rendered}"
    github_users_env   = "export GITHUB_USERS='${var.github_users}'"
    here               = "${path.module}"
  }
}

data "template_cloudinit_config" "cloud_config" {
  part {
    filename     = "cloud-config"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
  }

  part {
    filename     = "cloud-init"
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/cloud-init.bash")}"
  }
}

resource "aws_instance" "bench-instance" {
  count                  = 4
  instance_type          = "c5.9xlarge"
  user_data              = "${data.template_cloudinit_config.cloud_config.rendered}"
  ami                    = "ami-a43c8dde"
  vpc_security_group_ids = ["sg-7587c00f"]
  subnet_id              = "subnet-2f369b66"

  ebs_block_device {
    device_name = "/dev/xvdc"
    volume_type = "io1"
    volume_size = "750"
    iops        = "2250"
  }

  tags {
    Name = "${format("bench-instance-%02d", count.index + 1)}"
  }
}

# resource "aws_autoscaling_group" "workers" {
#   name                      = "${var.env}-${var.index}-workers-${var.site}"
#   default_cooldown          = 300
#   health_check_grace_period = 0
#   health_check_type         = "EC2"
#   launch_configuration      = "${aws_launch_configuration.workers.name}"
#   max_size                  = "${var.worker_asg_max_size}"
#   min_size                  = "${var.worker_asg_min_size}"
#   vpc_zone_identifier       = ["${split(",", var.worker_subnets)}"]
# 
#   termination_policies = [
#     "OldestLaunchConfiguration",
#     "OldestInstance",
#     "Default",
#   ]
# 
#   enabled_metrics = [
#     "GroupMinSize",
#     "GroupMaxSize",
#     "GroupDesiredCapacity",
#     "GroupInServiceInstances",
#     "GroupPendingInstances",
#     "GroupStandbyInstances",
#     "GroupTerminatingInstances",
#     "GroupTotalInstances",
#   ]
# 
#   tag {
#     key                 = "Name"
#     value               = "${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}"
#     propagate_at_launch = true
#   }
# 
#   tag {
#     key                 = "env"
#     value               = "${var.env}"
#     propagate_at_launch = true
#   }
# 
#   tag {
#     key                 = "queue"
#     value               = "${var.worker_queue}"
#     propagate_at_launch = true
#   }
# 
#   tag {
#     key                 = "role"
#     value               = "worker"
#     propagate_at_launch = true
#   }
# 
#   tag {
#     key                 = "site"
#     value               = "${var.site}"
#     propagate_at_launch = true
#   }
# 
#   tag {
#     key                 = "index"
#     value               = "${var.index}"
#     propagate_at_launch = true
#   }
# }

output "user_data" {
  value = "${data.template_file.cloud_config.rendered}"
}
