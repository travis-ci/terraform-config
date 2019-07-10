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

resource "kubernetes_secret" "gcloud_cleanup_config" {
  metadata {
    name      = "gcloud-cleanup-terraform"
    namespace = "${kubernetes_namespace.default.metadata.0.name}"
  }

  data = {
    GCLOUD_CLEANUP_ARCHIVE_BUCKET = "${google_storage_bucket.gcloud_cleanup_archive.name}"
    GCLOUD_CLEANUP_ACCOUNT_JSON   = "${base64decode(google_service_account_key.gcloud_cleanup.private_key)}"
  }
}
