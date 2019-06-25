variable "env" {}

variable "gcloud_cleanup_archive_retention_days" {
  default = 8
}

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
  default = "travisci/worker:v6.2.0"
}

variable "worker_image" {
  default = "projects/ubuntu-os-cloud/global/images/family/ubuntu-1804-lts"
}

variable "worker_managed_instance_count_com" {
  default = 0
}

variable "worker_managed_instance_count_com_free" {
  default = 0
}

variable "worker_managed_instance_count_org" {
  default = 0
}

variable "worker_machine_type" {
  default = "g1-small"
}

variable "worker_subnetwork" {}

variable "worker_zones" {
  default = ["a", "b", "c", "f"]
}

module "gce_workers" {
  source = "../gce_worker"

  config_com      = "${var.worker_config_com}"
  config_com_free = "${var.worker_config_com_free}"
  config_org      = "${var.worker_config_org}"

  env          = "${var.env}"
  github_users = "${var.github_users}"
  index        = "${var.index}"

  managed_instance_count_com      = "${var.worker_managed_instance_count_com}"
  managed_instance_count_com_free = "${var.worker_managed_instance_count_com_free}"
  managed_instance_count_org      = "${var.worker_managed_instance_count_org}"

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
    "cloudtrace.traces.patch",
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

# This key needs to be copied to travis-keychain.
# Ideally, this key is created as a Secret in k8s directly.
output "gcloud_cleanup_account_json" {
  value = "${base64decode(google_service_account_key.gcloud_cleanup.private_key)}"
}

output "workers_service_account_emails" {
  value = ["${module.gce_workers.workers_service_account_emails}"]
}

output "workers_service_account_names" {
  value = ["${module.gce_workers.workers_service_account_names}"]
}

output "redis_worker_rate_limit" {
  value = "${module.gce_workers.redis_worker_rate_limit}"
}
