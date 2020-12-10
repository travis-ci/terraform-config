variable "env" {
  default = "staging"
}

variable "index" {
  default = 1
}

variable "project" {
  default = "travis-staging-1"
}

variable "region" {
  default = "us-central1"
}

variable "REGISTRY_HTTP_TLS_CERTIFICATE" {}
variable "REGISTRY_HTTP_TLS_KEY" {}

variable "APPLICATION_DEFAULT_CREDENTIALS" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/docker-registry-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

module "docker_registry" {
  source = "../modules/docker_registry"

  cache_size_mb  = 40
  env            = var.env
  index          = var.index

  REGISTRY_HTTP_TLS_CERTIFICATE = "${var.REGISTRY_HTTP_TLS_CERTIFICATE}"
  REGISTRY_HTTP_TLS_KEY = "${var.REGISTRY_HTTP_TLS_KEY}"

  APPLICATION_DEFAULT_CREDENTIALS = var.APPLICATION_DEFAULT_CREDENTIALS
}
