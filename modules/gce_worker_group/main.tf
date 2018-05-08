variable "env" {}
variable "gcloud_cleanup_account_json" {}

variable "gcloud_cleanup_instance_filters" {
  default = "name eq ^(testing-gce|travis-job).*"
}

variable "gcloud_cleanup_instance_max_age" {
  default = "3h"
}

variable "gcloud_cleanup_job_board_url" {}

variable "gcloud_cleanup_loop_sleep" {
  default = "1s"
}

variable "gcloud_cleanup_scale" {
  default = "worker=1:Standard-1X"
}

variable "gcloud_cleanup_version" {
  default = "master"
}

variable "gcloud_zone" {}
variable "github_users" {}
variable "heroku_org" {}
variable "index" {}
variable "project" {}
variable "region" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "travisci_net_external_zone_id" {}
variable "worker_account_json_com" {}
variable "worker_account_json_org" {}
variable "worker_config_com" {}
variable "worker_config_org" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.6.0"
}

variable "worker_image" {}
variable "worker_instance_count_com" {}
variable "worker_instance_count_org" {}

variable "worker_machine_type" {
  default = "g1-small"
}

variable "worker_subnetwork" {}

variable "worker_zones" {
  default = ["a", "b", "c", "f"]
}

module "gce_workers" {
  source = "../gce_worker"

  account_json_com         = "${var.worker_account_json_com}"
  account_json_org         = "${var.worker_account_json_org}"
  config_com               = "${var.worker_config_com}"
  config_org               = "${var.worker_config_org}"
  env                      = "${var.env}"
  github_users             = "${var.github_users}"
  index                    = "${var.index}"
  instance_count_com       = "${var.worker_instance_count_com}"
  instance_count_org       = "${var.worker_instance_count_org}"
  machine_type             = "${var.worker_machine_type}"
  project                  = "${var.project}"
  region                   = "${var.region}"
  subnetwork_workers       = "${var.worker_subnetwork}"
  syslog_address_com       = "${var.syslog_address_com}"
  syslog_address_org       = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image             = "${var.worker_image}"
  zones                    = "${var.worker_zones}"
}

resource "heroku_app" "gcloud_cleanup" {
  name   = "gcloud-cleanup-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    BUILDPACK_URL                   = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    GCLOUD_CLEANUP_ACCOUNT_JSON     = "${var.gcloud_cleanup_account_json}"
    GCLOUD_CLEANUP_ENTITIES         = "instances"
    GCLOUD_CLEANUP_INSTANCE_FILTERS = "${var.gcloud_cleanup_instance_filters}"
    GCLOUD_CLEANUP_INSTANCE_MAX_AGE = "${var.gcloud_cleanup_instance_max_age}"
    GCLOUD_CLEANUP_JOB_BOARD_URL    = "${var.gcloud_cleanup_job_board_url}"
    GCLOUD_CLEANUP_LOOP_SLEEP       = "${var.gcloud_cleanup_loop_sleep}"
    GCLOUD_LOG_HTTP                 = "no-log-http"
    GCLOUD_PROJECT                  = "${var.project}"
    GCLOUD_ZONE                     = "${var.gcloud_zone}"
    GO_IMPORT_PATH                  = "github.com/travis-ci/gcloud-cleanup"
  }
}

resource "null_resource" "gcloud_cleanup" {
  triggers {
    config_signature = "${sha256(jsonencode(heroku_app.gcloud_cleanup.config_vars))}"
    heroku_id        = "${heroku_app.gcloud_cleanup.id}"
    ps_scale         = "${var.gcloud_cleanup_scale}"
    version          = "${var.gcloud_cleanup_version}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/heroku-wait-deploy-scale \
  --repo=travis-ci/gcloud-cleanup \
  --app=${heroku_app.gcloud_cleanup.id} \
  --ps-scale=${var.gcloud_cleanup_scale} \
  --deploy-version=${var.gcloud_cleanup_version}
EOF
  }
}
