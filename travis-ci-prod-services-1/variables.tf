variable "project_name" {
  default = "Production Services 1"
}

variable "project_id" {
  default = "travis-ci-prod-services-1"
}

variable "region" {
  default = "us-east1"
}

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

    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "bigquery.googleapis.com",
    "stackdriver.googleapis.com",
    "logging.googleapis.com",
    "cloudprofiler.googleapis.com",
    "runtimeconfig.googleapis.com",
    "deploymentmanager.googleapis.com",
    "redis.googleapis.com",
    "resourceviews.googleapis.com",
    "firestore.googleapis.com",
    "firebaserules.googleapis.com"
  ]
}
