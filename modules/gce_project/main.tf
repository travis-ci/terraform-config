variable "bastion_config" {}
variable "bastion_image" {}
variable "env" {}
variable "gcloud_cleanup_account_json" {}

variable "gcloud_cleanup_instance_filters" {
  default = "name eq ^(testing-gce|travis-job).*"
}

variable "gcloud_cleanup_instance_max_age" {
  default = "3h"
}

variable "gcloud_cleanup_job_board_url" {}

variable "gcloud_cleanup_loop_sleep" {
  default = "1s"
}

variable "gcloud_cleanup_scale" {
  default = "worker=1:Standard-1X"
}

variable "gcloud_cleanup_version" {
  default = "master"
}

variable "gcloud_zone" {}
variable "github_users" {}
variable "heroku_org" {}
variable "index" {}
variable "project" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "travisci_net_external_zone_id" {}
variable "worker_account_json_com" {}
variable "worker_account_json_org" {}
variable "worker_config_com" {}
variable "worker_config_org" {}

variable "worker_docker_self_image" {
  default = "travisci/worker:v3.4.0"
}

variable "worker_image" {}
variable "worker_instance_count_com" {}
variable "worker_instance_count_org" {}

variable "public_subnet_cidr_range" {
  default = "10.10.0.0/22"
}

variable "workers_subnet_cidr_range" {
  default = "10.10.4.0/22"
}

variable "jobs_org_subnet_cidr_range" {
  default = "10.20.0.0/16"
}

variable "jobs_com_subnet_cidr_range" {
  default = "10.30.0.0/16"
}

variable "build_com_subnet_cidr_range" {
  default = "10.10.12.0/22"
}

variable "build_org_subnet_cidr_range" {
  default = "10.10.8.0/22"
}

variable "zone_count" {
  default = "4"
}

variable "deny_target_ip_ranges" {
  type    = "list"
  default = []
}

resource "google_compute_network" "main" {
  name                    = "main"
  project                 = "${var.project}"
  auto_create_subnetworks = "false"
}

output "gce_network" {
  value = "${google_compute_network.main.self_link}"
}

resource "google_compute_subnetwork" "public" {
  name          = "public"
  ip_cidr_range = "${var.public_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

output "gce_subnetwork_public" {
  value = "${google_compute_subnetwork.public.self_link}"
}

resource "google_compute_subnetwork" "workers" {
  name          = "workers"
  ip_cidr_range = "${var.workers_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "jobs_org" {
  name          = "jobs-org"
  ip_cidr_range = "${var.jobs_org_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

# TODO: remove this legacy subnetwork when no longer in use
resource "google_compute_subnetwork" "build_org" {
  name          = "buildorg"
  ip_cidr_range = "${var.build_org_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_subnetwork" "jobs_com" {
  name          = "jobs-com"
  ip_cidr_range = "${var.jobs_com_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

# TODO: remove this legacy subnetwork when no longer in use
resource "google_compute_subnetwork" "build_com" {
  name          = "buildcom"
  ip_cidr_range = "${var.build_com_subnet_cidr_range}"
  network       = "${google_compute_network.main.self_link}"
  region        = "us-central1"

  project = "${var.project}"
}

resource "google_compute_firewall" "allow_public_ssh" {
  name          = "allow-public-ssh"
  network       = "${google_compute_network.main.name}"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]

  project = "${var.project}"

  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_public_icmp" {
  name          = "allow-public-icmp"
  network       = "${google_compute_network.main.name}"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nat", "bastion"]

  project = "${var.project}"

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = "${google_compute_network.main.name}"

  source_ranges = [
    "${google_compute_subnetwork.public.ip_cidr_range}",
    "${google_compute_subnetwork.workers.ip_cidr_range}",
  ]

  project = "${var.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_firewall" "allow_jobs_nat" {
  name    = "allow-jobs-nat"
  network = "${google_compute_network.main.name}"

  source_ranges = [
    "${google_compute_subnetwork.jobs_org.ip_cidr_range}",
    "${google_compute_subnetwork.jobs_com.ip_cidr_range}",
  ]

  target_tags = ["nat"]

  project = "${var.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_firewall" "deny_target_ip" {
  name    = "deny-target-ip"
  network = "${google_compute_network.main.name}"

  direction          = "EGRESS"
  destination_ranges = ["${var.deny_target_ip_ranges}"]

  project = "${var.project}"

  # highest priority
  priority = "0"

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }

  deny {
    protocol = "icmp"
  }
}

resource "google_compute_address" "nat-b" {
  name    = "nat-b"
  region  = "us-central1"
  project = "${var.project}"
}

resource "aws_route53_record" "nat-b" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat-${var.env}-${var.index}.gce-us-central1-b.travisci.net"
  type    = "A"
  ttl     = 5

  records = [
    "${google_compute_address.nat-b.address}",
  ]
}

resource "google_compute_address" "bastion-b" {
  name    = "bastion-b"
  region  = "us-central1"
  project = "${var.project}"
}

resource "aws_route53_record" "bastion-b" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "bastion-${var.env}-${var.index}.gce-us-central1-b.travisci.net"
  type    = "A"
  ttl     = 5

  records = [
    "${google_compute_address.bastion-b.address}",
  ]
}

data "template_file" "bastion_cloud_config" {
  template = "${file("${path.module}/bastion-cloud-config.yml.tpl")}"

  vars {
    bastion_config   = "${var.bastion_config}"
    cloud_init_bash  = "${file("${path.module}/bastion-cloud-init.bash")}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    syslog_address   = "${var.syslog_address_com}"
  }
}

resource "google_compute_instance" "bastion-b" {
  name         = "${var.env}-${var.index}-bastion-b"
  machine_type = "g1-small"
  zone         = "us-central1-b"
  tags         = ["bastion", "${var.env}"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.bastion_image}"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "public"

    access_config {
      nat_ip = "${google_compute_address.bastion-b.address}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.bastion_cloud_config.rendered}"
  }
}

module "gce_worker_a" {
  source = "../gce_worker"

  account_json_com         = "${var.worker_account_json_com}"
  account_json_org         = "${var.worker_account_json_org}"
  config_com               = "${var.worker_config_com}"
  config_org               = "${var.worker_config_org}"
  env                      = "${var.env}"
  github_users             = "${var.github_users}"
  index                    = "${var.index}"
  instance_count_com       = "${var.worker_instance_count_com / var.zone_count}"
  instance_count_org       = "${var.worker_instance_count_org / var.zone_count}"
  machine_type             = "g1-small"
  project                  = "${var.project}"
  subnetwork_workers       = "${google_compute_subnetwork.workers.self_link}"
  syslog_address_com       = "${var.syslog_address_com}"
  syslog_address_org       = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image             = "${var.worker_image}"
  zone                     = "us-central1-a"
  zone_suffix              = "a"
}

module "gce_worker_b" {
  source = "../gce_worker"

  account_json_com         = "${var.worker_account_json_com}"
  account_json_org         = "${var.worker_account_json_org}"
  config_com               = "${var.worker_config_com}"
  config_org               = "${var.worker_config_org}"
  env                      = "${var.env}"
  github_users             = "${var.github_users}"
  index                    = "${var.index}"
  instance_count_com       = "${var.worker_instance_count_com / var.zone_count}"
  instance_count_org       = "${var.worker_instance_count_org / var.zone_count}"
  machine_type             = "g1-small"
  project                  = "${var.project}"
  subnetwork_workers       = "${google_compute_subnetwork.workers.self_link}"
  syslog_address_com       = "${var.syslog_address_com}"
  syslog_address_org       = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image             = "${var.worker_image}"
  zone                     = "us-central1-b"
  zone_suffix              = "b"
}

module "gce_worker_c" {
  source = "../gce_worker"

  account_json_com         = "${var.worker_account_json_com}"
  account_json_org         = "${var.worker_account_json_org}"
  config_com               = "${var.worker_config_com}"
  config_org               = "${var.worker_config_org}"
  env                      = "${var.env}"
  github_users             = "${var.github_users}"
  index                    = "${var.index}"
  instance_count_com       = "${var.worker_instance_count_com / var.zone_count}"
  instance_count_org       = "${var.worker_instance_count_org / var.zone_count}"
  machine_type             = "g1-small"
  project                  = "${var.project}"
  subnetwork_workers       = "${google_compute_subnetwork.workers.self_link}"
  syslog_address_com       = "${var.syslog_address_com}"
  syslog_address_org       = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image             = "${var.worker_image}"
  zone                     = "us-central1-c"
  zone_suffix              = "c"
}

module "gce_worker_f" {
  source = "../gce_worker"

  account_json_com         = "${var.worker_account_json_com}"
  account_json_org         = "${var.worker_account_json_org}"
  config_com               = "${var.worker_config_com}"
  config_org               = "${var.worker_config_org}"
  env                      = "${var.env}"
  github_users             = "${var.github_users}"
  index                    = "${var.index}"
  instance_count_com       = "${var.worker_instance_count_com / var.zone_count}"
  instance_count_org       = "${var.worker_instance_count_org / var.zone_count}"
  machine_type             = "g1-small"
  project                  = "${var.project}"
  subnetwork_workers       = "${google_compute_subnetwork.workers.self_link}"
  syslog_address_com       = "${var.syslog_address_com}"
  syslog_address_org       = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image             = "${var.worker_image}"
  zone                     = "us-central1-f"
  zone_suffix              = "f"
}

resource "heroku_app" "gcloud_cleanup" {
  name   = "gcloud-cleanup-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    BUILDPACK_URL                   = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    GCLOUD_CLEANUP_ACCOUNT_JSON     = "${var.gcloud_cleanup_account_json}"
    GCLOUD_CLEANUP_ENTITIES         = "instances"
    GCLOUD_CLEANUP_INSTANCE_FILTERS = "${var.gcloud_cleanup_instance_filters}"
    GCLOUD_CLEANUP_INSTANCE_MAX_AGE = "${var.gcloud_cleanup_instance_max_age}"
    GCLOUD_CLEANUP_JOB_BOARD_URL    = "${var.gcloud_cleanup_job_board_url}"
    GCLOUD_CLEANUP_LOOP_SLEEP       = "${var.gcloud_cleanup_loop_sleep}"
    GCLOUD_LOG_HTTP                 = "no-log-http"
    GCLOUD_PROJECT                  = "${var.project}"
    GCLOUD_ZONE                     = "${var.gcloud_zone}"
    GO_IMPORT_PATH                  = "github.com/travis-ci/gcloud-cleanup"
  }
}

resource "null_resource" "gcloud_cleanup" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.gcloud_cleanup.config_vars.0)))}"
    heroku_id        = "${heroku_app.gcloud_cleanup.id}"
    ps_scale         = "${var.gcloud_cleanup_scale}"
    version          = "${var.gcloud_cleanup_version}"
  }

  provisioner "local-exec" {
    command = "exec ${path.module}/../../bin/heroku-wait-deploy-scale travis-ci/gcloud-cleanup ${heroku_app.gcloud_cleanup.id} ${var.gcloud_cleanup_scale} ${var.gcloud_cleanup_version}"
  }
}
