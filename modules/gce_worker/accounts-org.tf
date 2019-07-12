resource "google_service_account" "workers_org" {
  account_id   = "workers-org-${lookup(var.regions_abbrev, var.region, "unk")}"
  display_name = "travis-worker processes org ${var.region}"
}

resource "google_project_iam_member" "workers_org" {
  role   = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member = "serviceAccount:${google_service_account.workers_org.email}"
}

resource "google_service_account_key" "workers_org" {
  service_account_id = "${google_service_account.workers_org.email}"
}
