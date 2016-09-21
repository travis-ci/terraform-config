variable "cyclist_auth_tokens" {}
variable "cyclist_aws_region" { default = "us-east-1" }
variable "cyclist_debug" { default = "false" }
variable "cyclist_redis_plan" { default = "premium-0" }
variable "cyclist_scale" { default = "web=1:Standard-1X" }
variable "cyclist_version" { default = "master" }
variable "env" {}
variable "heroku_org" {}
variable "index" {}
variable "security_groups" {}
variable "site" {}
variable "syslog_address" {}
variable "worker_ami" {}
variable "worker_asg_max_size" { default = 5 }
variable "worker_asg_min_size" { default = 1 }
variable "worker_asg_namespace" {}
variable "worker_asg_scale_in_cooldown" { default = 300 }
variable "worker_asg_scale_in_qty" { default = -1 }
variable "worker_asg_scale_in_threshold" { default = "64.0" }
variable "worker_asg_scale_out_cooldown" { default = 300 }
variable "worker_asg_scale_out_qty" { default = 1 }
variable "worker_asg_scale_out_threshold" { default = "48.0" }
variable "worker_config" {}
variable "worker_docker_image_android" {}
variable "worker_docker_image_default" {}
variable "worker_docker_image_erlang" {}
variable "worker_docker_image_go" {}
variable "worker_docker_image_haskell" {}
variable "worker_docker_image_jvm" {}
variable "worker_docker_image_node_js" {}
variable "worker_docker_image_perl" {}
variable "worker_docker_image_php" {}
variable "worker_docker_image_python" {}
variable "worker_docker_image_ruby" {}
variable "worker_docker_self_image" { default = "quay.io/travisci/worker:v2.4.0" }
variable "worker_queue" {}
variable "worker_subnets" {}
