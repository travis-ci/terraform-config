variable "dns_domain" {
  default = "travisci.net"
}

variable "env" {}
variable "github_users" {}

variable "image" {
  default = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "index" {}
variable "name" {}
variable "project" {}
variable "gcloud_zone" {}

variable "region" {
  default = "us-central1"
}

variable "repos" {
  type = "list"
}

variable "syslog_address" {}

variable "zone" {
  default = "us-central1-f"
}

variable "machine_type" {
  default = "g1-small"
}

variable "subnetwork" {}

variable "google_redis_instance" {
  default = "redis://localhost:6379"
}

variable "gcloud_cleanup_archive_retention_days" {
  default = 8
}

variable "gcloud_cleanup_instance_filters" {
  default = "name eq ^(testing-gce|travis-job|packer-).*"
}

variable "gcloud_cleanup_instance_max_age" {
  default = "3h"
}

variable "gcloud_cleanup_job_board_url" {}

variable "gcloud_cleanup_loop_sleep" {
  default = "1m"
}

variable "gcloud_cleanup_opencensus_sampling_rate" {}

variable "gcloud_cleanup_opencensus_tracing_enabled" {
  default = "false"
}

variable "gcloud_cleanup_scale" {
  default = "worker=1:Standard-1X"
}

variable "gcloud_cleanup_version" {
  default = "master"
}

variable "gcloud_cleanup_docker_self_image" {
  default = "travisci/gcloud-cleanup:latest"
}
