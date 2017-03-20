variable "rabbitmq_admin_password" { default = "guest" }
variable "rabbitmq_admin_username" { default = "guest" }
variable "rabbitmq_host" {}
variable "rabbitmq_username" { default = "test" }
variable "rabbitmq_vhost" { default = "/" }

terraform {
  backend "local" {
    path = "local-development-0.tfstate"
  }
}

module "rabbitmq_config_test" {
  source = "../modules/rabbitmq_user"
  admin_password = "${var.rabbitmq_admin_password}"
  admin_username = "${var.rabbitmq_admin_username}"
  endpoint = "${var.rabbitmq_host}"
  username = "test"
  vhost = "/"
}
