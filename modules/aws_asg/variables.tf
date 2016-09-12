variable "env" {}
variable "security_groups" {}
variable "site" {}
variable "sns_subscription_endpoint" {}
variable "sns_subscription_protocol" { default = "https" }
variable "worker_ami" {}
variable "worker_asg_max_size" { default = 5 }
variable "worker_asg_min_size" { default = 1 }
variable "worker_config" {}
variable "workers_subnets" {}
