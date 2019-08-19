variable "project_name" {}
variable "project_id" {}

resource "google_project" "project" {
  name       = "${var.project_name}"
  project_id = "${var.project_id}"
}

resource "google_project_services" "project" {
  project = "${google_project.project.project_id}"

  services = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "storage-component.googleapis.com",
  ]
}

output "project_id" {
  value = "${google_project.project.project_id}"
}
