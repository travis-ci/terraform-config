variable "env" {}

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
variable "worker_config_com" {}
variable "worker_config_com_free" {}
variable "worker_config_org" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.10.1"
}

variable "worker_image" {}
variable "worker_instance_count_com" {}
variable "worker_instance_count_com_free" {}
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

  config_com               = "${var.worker_config_com}"
  config_com_free          = "${var.worker_config_com_free}"
  config_org               = "${var.worker_config_org}"
  env                      = "${var.env}"
  github_users             = "${var.github_users}"
  index                    = "${var.index}"
  instance_count_com       = "${var.worker_instance_count_com}"
  instance_count_com_free  = "${var.worker_instance_count_com_free}"
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

resource "google_storage_bucket" "gcloud_cleanup_archive" {
  name    = "gcloud-cleanup-${var.env}-${var.index}"
  project = "${var.project}"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = "${var.gcloud_cleanup_archive_retention_days}"
    }
  }
}

resource "google_project_iam_custom_role" "gcloud_cleaner" {
  role_id     = "gcloud_cleaner"
  title       = "Gcloud Cleaner"
  description = "A gcloud-cleanup process that can clean and archive stuff"

  permissions = [
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.disks.update",
    "compute.globalOperations.get",
    "compute.globalOperations.list",
    "compute.images.delete",
    "compute.images.get",
    "compute.images.list",
    "compute.instances.delete",
    "compute.instances.deleteAccessConfig",
    "compute.instances.detachDisk",
    "compute.instances.get",
    "compute.instances.getSerialPortOutput",
    "compute.instances.list",
    "compute.instances.reset",
    "compute.instances.stop",
    "compute.instances.update",
    "compute.regions.get",
    "compute.regions.list",
    "compute.zones.get",
    "compute.zones.list",
    "storage.objects.create",
    "storage.objects.update",
  ]
}

resource "google_service_account" "gcloud_cleanup" {
  account_id   = "gcloud-cleanup"
  display_name = "Gcloud Cleanup"
  project      = "${var.project}"
}

resource "google_project_iam_member" "gcloud_cleaner" {
  project = "${var.project}"
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.gcloud_cleaner.role_id}"
  member  = "serviceAccount:${google_service_account.gcloud_cleanup.email}"
}

resource "google_service_account_key" "gcloud_cleanup" {
  service_account_id = "${google_service_account.gcloud_cleanup.email}"
}

resource "heroku_app" "gcloud_cleanup" {
  name   = "gcloud-cleanup-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    BUILDPACK_URL                      = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    GCLOUD_CLEANUP_ACCOUNT_JSON        = "${base64decode(google_service_account_key.gcloud_cleanup.private_key)}"
    GCLOUD_CLEANUP_ARCHIVE_BUCKET      = "${google_storage_bucket.gcloud_cleanup_archive.name}"
    GCLOUD_CLEANUP_ARCHIVE_SERIAL      = "true"
    GCLOUD_CLEANUP_ARCHIVE_SAMPLE_RATE = "10"
    GCLOUD_CLEANUP_ENTITIES            = "instances"
    GCLOUD_CLEANUP_INSTANCE_FILTERS    = "${var.gcloud_cleanup_instance_filters}"
    GCLOUD_CLEANUP_INSTANCE_MAX_AGE    = "${var.gcloud_cleanup_instance_max_age}"
    GCLOUD_CLEANUP_JOB_BOARD_URL       = "${var.gcloud_cleanup_job_board_url}"
    GCLOUD_CLEANUP_LOOP_SLEEP          = "${var.gcloud_cleanup_loop_sleep}"
    GCLOUD_LOG_HTTP                    = "no-log-http"
    GCLOUD_PROJECT                     = "${var.project}"
    GCLOUD_ZONE                        = "${var.gcloud_zone}"
    GO_IMPORT_PATH                     = "github.com/travis-ci/gcloud-cleanup"
    MANAGED_VIA                        = "github.com/travis-ci/terraform-config"
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

output "workers_service_account_email" {
  value = "${module.gce_workers.workers_service_account_email}"
}

output "workers_service_account_name" {
  value = "${module.gce_workers.workers_service_account_name}"
}
