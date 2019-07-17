variable "aws_com_id" {}
variable "aws_com_secret" {}
variable "aws_com_trace_bucket" {}
variable "aws_org_id" {}
variable "aws_org_secret" {}
variable "aws_org_trace_bucket" {}
variable "env" {}
variable "index" {}
variable "k8s_default_namespace" {}
variable "project" {}
variable "region" {}
variable "worker_network" {}
variable "worker_subnetwork" {}

variable "gcloud_cleanup_archive_retention_days" {
  default = 8
}
