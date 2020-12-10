variable "env" {
  default = "production"
}

variable "index" {
  default = 1
}

variable "project" {
  default = "travis-ci-prod-3"
}

variable "region" {
  default = "us-central1"
}

variable "machine_type" {
  default = "n1-standard-4"
}

variable "target_size" {
  default = 2
}

variable "REGISTRY_HTTP_TLS_CERTIFICATE" {}
variable "REGISTRY_HTTP_TLS_KEY" {}

variable "APPLICATION_DEFAULT_CREDENTIALS" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/docker-registry-production-3.tfstate"
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

  cache_size_mb  = 3000
  env            = var.env
  index          = var.index
  machine_type   = var.machine_type
  target_size    = var.target_size

  REGISTRY_HTTP_TLS_CERTIFICATE = "${var.REGISTRY_HTTP_TLS_CERTIFICATE}"
  REGISTRY_HTTP_TLS_KEY = "${var.REGISTRY_HTTP_TLS_KEY}"

  APPLICATION_DEFAULT_CREDENTIALS = var.APPLICATION_DEFAULT_CREDENTIALS
}

module "docker_registry_east" {
  source = "../modules/docker_registry"

  cache_size_mb  = 3000
  env            = var.env
  index          = var.index
  machine_type   = var.machine_type
  target_size    = var.target_size
  network        = "main-us-east1"

  REGISTRY_HTTP_TLS_CERTIFICATE = "${var.REGISTRY_HTTP_TLS_CERTIFICATE}"
  REGISTRY_HTTP_TLS_KEY = "${var.REGISTRY_HTTP_TLS_KEY}"

  APPLICATION_DEFAULT_CREDENTIALS = var.APPLICATION_DEFAULT_CREDENTIALS

  prefix = "-east"
  region = "us-east1"
  zones  = ["b", "c", "d"]
}
