variable "bastion_config" {}
variable "bastion_image" {}
variable "env" {}
variable "gcloud_cleanup_account_json" {}
variable "gcloud_cleanup_instance_max_age" { default = "3h" }
variable "gcloud_cleanup_job_board_url" {}
variable "gcloud_cleanup_loop_sleep" { default = "1s" }
variable "gcloud_cleanup_scale" { default = "worker=1:Standard-1X" }
variable "gcloud_zone" {}
variable "heroku_org" {}
variable "index" {}
variable "nat_image" {}
variable "project" {}
variable "worker_account_json_com" {}
variable "worker_account_json_org" {}
variable "worker_chef_json_com" {}
variable "worker_chef_json_org" {}
variable "worker_config_com" {}
variable "worker_config_org" {}
variable "worker_image" {}
