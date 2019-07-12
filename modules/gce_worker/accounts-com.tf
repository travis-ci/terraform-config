resource "google_service_account" "workers_com" {
  account_id   = "workers-com-${lookup(var.regions_abbrev, var.region, "unk")}"
  display_name = "travis-worker processes com ${var.region}"
}

resource "google_project_iam_member" "workers_com" {
  role   = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member = "serviceAccount:${google_service_account.workers_com.email}"
}

resource "google_service_account_key" "workers_com" {
  service_account_id = "${google_service_account.workers_com.email}"
}

resource "kubernetes_secret" "worker_com_config" {
  metadata {
    name      = "worker-com-terraform"
    namespace = "${kubernetes_namespace.default.metadata.0.name}"
  }

  data = {
    TRAVIS_WORKER_GCE_ACCOUNT_JSON               = "${base64decode(google_service_account_key.worker_com.private_key)}"
    TRAVIS_WORKER_STACKDRIVER_TRACE_ACCOUNT_JSON = "${base64decode(google_service_account_key.workers_com.private_key)}"
  }
}
