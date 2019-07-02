variable "project" {}
variable "region" {}
variable "env" {}
variable "index" {}

variable "github_users" {}
variable "librato_email" {}
variable "librato_token" {}
variable "syslog_address" {}

variable "allowed_internal_ranges" {
  default = ["10.0.0.0/8"]
}

variable "cache_size_mb" {
  default = 204800
}

variable "dns_domain" {
  default = "travisci.net"
}

variable "gce_health_check_source_ranges" {
  default = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}

variable "machine_type" {
  default = "n1-standard-2" # 2vCPU, 7.5GB RAM
}

variable "network" {
  default = "main"
}

variable "target_size" {
  default = 2
}

data "google_compute_zones" "zones" {
  project = "${var.project}"
  region  = "${var.region}"
}

data "aws_route53_zone" "travisci_net" {
  name = "${var.dns_domain}."
}

data "template_file" "nginx_conf_d_default" {
  template = "${file("${path.module}/nginx-conf.d-default.conf.tpl")}"

  vars {
    max_size = "${replace("${var.cache_size_mb * 0.8}", "/\\..*/", "")}m"
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets               = "${path.module}/../../../../assets"
    here                 = "${path.module}"
    nginx_conf_d_default = "${data.template_file.nginx_conf_d_default.rendered}"
    syslog_address       = "${var.syslog_address}"

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF

    librato_env = <<EOF
export LIBRATO_EMAIL=${var.librato_email}
export LIBRATO_TOKEN=${var.librato_token}
EOF
  }
}

resource "google_compute_subnetwork" "build_cache" {
  enable_flow_logs = "true"
  ip_cidr_range    = "10.80.1.0/24"
  name             = "build-cache"
  network          = "${var.network}"
  region           = "${var.region}"
}

resource "google_compute_firewall" "allow_build_cache_internal" {
  name        = "allow-build-cache-internal"
  network     = "${var.network}"
  target_tags = ["build-cache"]

  source_ranges = ["${var.allowed_internal_ranges}"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_build_cache_health_check" {
  name        = "allow-build-cache-health-check"
  network     = "${var.network}"
  target_tags = ["build-cache"]

  source_ranges = ["${var.gce_health_check_source_ranges}"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_address" "build_cache_frontend" {
  name         = "build-cache-frontend"
  subnetwork   = "${google_compute_subnetwork.build_cache.self_link}"
  address_type = "INTERNAL"
  address      = "${cidrhost("10.80.1.0/24", 2)}"
}

resource "google_compute_health_check" "build_cache" {
  name = "build-cache-health-check"

  timeout_sec        = 3
  check_interval_sec = 5

  http_health_check {
    request_path = "/__squignix_health__"
  }
}

resource "google_compute_instance_template" "build_cache" {
  project      = "${var.project}"
  name_prefix  = "build-cache-"
  machine_type = "${var.machine_type}"
  tags         = ["build-cache", "${var.env}"]

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    disk_size_gb = "${ceil(var.cache_size_mb / 1024.0)}"
    disk_type    = "pd-ssd"
    source_image = "ubuntu-os-cloud/ubuntu-1804-lts"
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.build_cache.self_link}"
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

resource "google_compute_target_pool" "build_cache" {
  name = "build-cache"
}

resource "google_compute_region_instance_group_manager" "build_cache" {
  provider = "google-beta"

  base_instance_name        = "${var.env}-${var.index}-build-cache"
  distribution_policy_zones = ["${data.google_compute_zones.zones.names}"]
  name                      = "build-cache"
  region                    = "${var.region}"
  target_pools              = ["${google_compute_target_pool.build_cache.self_link}"]
  target_size               = "${var.target_size}"

  version {
    name              = "default"
    instance_template = "${google_compute_instance_template.build_cache.self_link}"
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_unavailable_fixed = "${length(data.google_compute_zones.zones.names)}"
    max_surge_fixed       = "${length(data.google_compute_zones.zones.names)}"
    min_ready_sec         = 900
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.build_cache.self_link}"
    initial_delay_sec = 900
  }
}

resource "google_compute_region_backend_service" "build_cache" {
  name             = "build-cache-backend"
  description      = "backend servers for build cache"
  protocol         = "TCP"
  session_affinity = "CLIENT_IP"
  timeout_sec      = 10

  backend {
    group = "${google_compute_region_instance_group_manager.build_cache.instance_group}"
  }

  health_checks = ["${google_compute_health_check.build_cache.self_link}"]
}

resource "google_compute_forwarding_rule" "build_cache" {
  name                  = "build-cache-forwarding"
  backend_service       = "${google_compute_region_backend_service.build_cache.self_link}"
  ip_address            = "${google_compute_address.build_cache_frontend.address}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  network               = "main"
  ports                 = ["80"]
  subnetwork            = "${google_compute_subnetwork.build_cache.self_link}"
}

resource "aws_route53_record" "build_cache_frontend" {
  zone_id = "${data.aws_route53_zone.travisci_net.zone_id}"
  name    = "${var.env}-${var.index}-build-cache.gce-${var.region}.${var.dns_domain}"
  type    = "A"
  ttl     = 5

  records = ["${google_compute_address.build_cache_frontend.address}"]
}

output "dns_fqdn" {
  value = "${aws_route53_record.build_cache_frontend.name}"
}
