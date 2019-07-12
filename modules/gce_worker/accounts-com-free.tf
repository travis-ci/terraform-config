resource "google_service_account" "workers_com_free" {
  account_id   = "workers-com-free-${lookup(var.regions_abbrev, var.region, "unk")}"
  display_name = "travis-worker processes com free ${var.region}"
}

resource "google_project_iam_member" "workers_com_free" {
  role   = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member = "serviceAccount:${google_service_account.workers_com_free.email}"
}

resource "google_service_account_key" "workers_com_free" {
  service_account_id = "${google_service_account.workers_com_free.email}"
}

resource "kubernetes_secret" "worker_com_free_config" {
  metadata {
    name      = "worker-com-free-terraform"
    namespace = "${kubernetes_namespace.default.metadata.0.name}"
  }

  data = {
    TRAVIS_WORKER_GCE_ACCOUNT_JSON               = "${base64decode(google_service_account_key.worker_com_free.private_key)}"
    TRAVIS_WORKER_STACKDRIVER_TRACE_ACCOUNT_JSON = "${base64decode(google_service_account_key.workers_com_free.private_key)}"
  }
}
