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
