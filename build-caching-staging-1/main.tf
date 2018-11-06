variable "cache_size_mb" {
  default = 1848
}

variable "env" {
  default = "staging"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "machine_type" {
  default = "custom-1-2048"
}

variable "project" {
  default = "travis-staging-1"
}

variable "region" {
  default = "us-central1"
}

variable "syslog_address_com" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/build-caching-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "google-beta" {
  project = "${var.project}"
  region  = "${var.region}"
}

provider "aws" {}

data "template_file" "nginx_conf_d_default" {
  template = "${file("${path.module}/nginx-conf.d-default.conf.tpl")}"

  vars {
    max_size = "${replace("${var.cache_size_mb * 0.9}", "/\\..*/", "")}m"
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets               = "${path.module}/../assets"
    here                 = "${path.module}"
    nginx_conf_d_default = "${data.template_file.nginx_conf_d_default.rendered}"
    syslog_address       = "${var.syslog_address_com}"

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF

    squignix_env = <<EOF
### squignix.env
${file("${path.module}/squignix.env")}

### in-line
export SQUIGNIX_CACHE_SIZE=${format("%dk", var.cache_size_mb * 1024)}
EOF
  }
}

resource "google_compute_firewall" "build_cache" {
  name      = "build-cache"
  network   = "main"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "11371"]
  }

  target_tags = ["build-cache"]
}

resource "google_compute_address" "build_cache" {
  name    = "build-cache-1"
  region  = "${var.region}"
  project = "${var.project}"
}

resource "aws_route53_record" "build_cache" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "build-cache-${var.env}-${var.index}.gce-${var.region}.travisci.net"
  type    = "A"
  ttl     = 5

  records = ["${google_compute_address.build_cache.address}"]
}

resource "google_compute_health_check" "build_cache" {
  name = "build-cache-health-check"

  timeout_sec        = 3
  check_interval_sec = 5

  http_health_check {
    request_path = "/__squignix_health__"
  }
}

resource "google_compute_backend_service" "build_cache" {
  name        = "build-cache-backend"
  description = "backend servers for build cache"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group_manager.build_cache.instance_group}"
  }

  health_checks = ["${google_compute_health_check.build_cache.self_link}"]
}

resource "google_compute_instance_template" "build_cache" {
  name_prefix  = "${var.env}-${var.index}-build-cache-"
  machine_type = "${var.machine_type}"
  tags         = ["build-cache", "${var.env}"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-1804-lts"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "public"

    access_config = {}
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config.rendered}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "build_cache" {
  provider = "google-beta"

  base_instance_name = "${var.env}-${var.index}-build-cache-gce"
  name               = "build-cache"
  target_size        = 2
  zone               = "us-central1-a"

  version {
    name              = "default"
    instance_template = "${google_compute_instance_template.build_cache.self_link}"
  }

  update_policy {
    type                    = "PROACTIVE"
    minimal_action          = "REPLACE"
    max_surge_percent       = 100
    max_unavailable_percent = 50
    min_ready_sec           = 900
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.build_cache.self_link}"
    initial_delay_sec = 900
  }
}

resource "google_compute_url_map" "build_cache" {
  name        = "build-cache"
  description = "url map for build cache"

  default_service = "${google_compute_backend_service.build_cache.self_link}"
}

resource "google_compute_target_http_proxy" "build_cache" {
  name    = "build-cache"
  url_map = "${google_compute_url_map.build_cache.self_link}"
}

resource "google_compute_forwarding_rule" "build_cache" {
  name                  = "build-cache-forwarding-rule"
  ip_address            = "${google_compute_address.build_cache.self_link}"
  load_balancing_scheme = "EXTERNAL"
  target                = "${google_compute_target_http_proxy.build_cache.self_link}"
  port_range            = "80,8080"
}
