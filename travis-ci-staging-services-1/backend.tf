terraform {
  backend "gcs" {
    bucket = "travis-terraform-state"
    prefix = "travis-ci-staging-services-1"
  }
}
