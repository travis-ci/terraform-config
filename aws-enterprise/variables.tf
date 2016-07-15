variable "env" {
  default = "enterprise"
}
variable "aws_bastion_ami" {}
variable "aws_worker_ami" {}
variable "aws_nat_ami" {}

variable "bastion_key_name" {}
variable "enterprise_host_name" {
  description = "The fully qualified hostname of the Travis Enterprise Platform."
}

variable "rabbitmq_password" {
  description = "The password of the Enterprise Platform RabbitMQ."
}
