data "terraform_remote_state" "staging_1" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-staging-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

data "terraform_remote_state" "production_2" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-2.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

data "terraform_remote_state" "production_3" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-3.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

resource "google_project_iam_member" "staging_1_workers" {
  count   = "${length(data.terraform_remote_state.staging_1.workers_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.staging_1.workers_service_account_emails, count.index)}"
}

resource "google_project_iam_member" "production_2_workers" {
  count   = "${length(data.terraform_remote_state.production_2.workers_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.production_2.workers_service_account_emails, count.index)}"
}

resource "google_project_iam_member" "production_3_workers" {
  count   = "${length(data.terraform_remote_state.production_3.workers_service_account_emails)}"
  project = "${var.project}"
  role    = "roles/compute.imageUser"
  member  = "serviceAccount:${element(data.terraform_remote_state.production_3.workers_service_account_emails, count.index)}"
}
