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
