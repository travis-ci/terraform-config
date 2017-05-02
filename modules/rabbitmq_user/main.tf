variable "admin_password" {}
variable "admin_username" {}
variable "endpoint" {}

variable "perm_configure" {
  default = ".*"
}

variable "perm_read" {
  default = ".*"
}

variable "perm_write" {
  default = ".*"
}

variable "scheme" {
  default = "amqp"
}

variable "username" {}
variable "vhost" {}

provider "rabbitmq" {
  endpoint = "${var.endpoint}"
  password = "${var.admin_password}"
  username = "${var.admin_username}"
}

resource "random_id" "password" {
  byte_length = 32
}

resource "rabbitmq_user" "user" {
  name     = "${var.username}"
  password = "${random_id.password.hex}"
  tags     = ["travis"]
}

resource "rabbitmq_permissions" "perms" {
  permissions {
    configure = "${var.perm_configure}"
    read      = "${var.perm_read}"
    write     = "${var.perm_write}"
  }

  user  = "${rabbitmq_user.user.name}"
  vhost = "${var.vhost}"
}

output "uri" {
  value = "${var.scheme}://${rabbitmq_user.user.name}:${rabbitmq_user.user.password}@${element(split("//", var.endpoint), 1)}/${var.vhost}"
}
