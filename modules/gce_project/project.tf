variable "project_id" {}

variable "default_services" {
  default = [
    "bigquery-json.googleapis.com",
    "bigquerystorage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "storage-api.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "storage-component.googleapis.com",
  ]
}

data "google_project" "project" {
  project_id = "${var.project_id}"
}

resource "google_project_services" "project" {
  project = "${data.google_project.project.project_id}"

  services = "${var.default_services}"
}

output "project_id" {
  value = "${data.google_project.project.project_id}"
}
