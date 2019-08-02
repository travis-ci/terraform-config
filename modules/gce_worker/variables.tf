variable "aws_com_id" {}
variable "aws_com_secret" {}
variable "aws_com_trace_bucket" {}
variable "aws_org_id" {}
variable "aws_org_secret" {}
variable "aws_org_trace_bucket" {}
variable "k8s_namespace" {}
variable "project" {}
variable "region" {}

variable "regions_abbrev" {
  default = {
    "us-central1" = "uc1"
    "us-east1"    = "ue1"
  }
}
