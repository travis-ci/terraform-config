variable "host" {}
variable "cluster_ca_certificate" {}
variable "client_certificate" {}
variable "client_key" {}

variable "image_builder_secrets" {
  default = {}
}
