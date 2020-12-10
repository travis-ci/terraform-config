variable "allowed_internal_ranges" {
  default = ["10.0.0.0/8"]
}

variable "cache_size_mb" {
  default = 102400
}

variable "env" {}

variable "gce_health_check_source_ranges" {
  default = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}

variable "index" {}

variable "machine_type" {
  default = "n1-standard-2"
}

variable "network" {
  default = "main"
}

variable "region" {
  default = "us-central1"
}

variable "prefix" {
  default = ""
}

variable "target_size" {
  default = 2
}

variable "zones" {
  default = ["a", "b", "c", "f"]
}

variable "REGISTRY_HTTP_TLS_CERTIFICATE" {}
variable "REGISTRY_HTTP_TLS_KEY" {}

variable "APPLICATION_DEFAULT_CREDENTIALS" {}

data "template_file" "docker_registry_config" {
  template = "${file("${path.module}/config.yml.tpl")}"
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars = {
    assets                 = "${path.module}/../../../../assets"
    here                   = "${path.module}"
    docker_registry_config = "${data.template_file.docker_registry_config.rendered}"

    registry_env = <<EOF
REGISTRY_HTTP_TLS_CERTIFICATE=/etc/ssl/docker/tls.crt
REGISTRY_HTTP_TLS_KEY=/etc/ssl/docker/tls.key
EOF

    REGISTRY_HTTP_TLS_CERTIFICATE = "${var.REGISTRY_HTTP_TLS_CERTIFICATE}"
    REGISTRY_HTTP_TLS_KEY         = "${var.REGISTRY_HTTP_TLS_KEY}"

    APPLICATION_DEFAULT_CREDENTIALS = var.APPLICATION_DEFAULT_CREDENTIALS
  }
}

resource "google_compute_subnetwork" "docker_registry" {
  ip_cidr_range    = "10.90.1.0/24"
  name             = "docker-registry${var.prefix}"
  network          = var.network
  region           = var.region
}

resource "google_compute_firewall" "allow_docker_registry_internal" {
  name        = "allow-docker-registry-internal${var.prefix}"
  network     = var.network
  target_tags = ["docker-registry"]

  source_ranges = var.allowed_internal_ranges

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_docker_registry_health_check" {
  name        = "allow-docker-registry-health-check${var.prefix}"
  network     = var.network
  target_tags = ["docker-registry"]

  source_ranges = var.gce_health_check_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

resource "google_compute_address" "docker_registry_frontend" {
  name         = "docker-registry-frontend${var.prefix}"
  subnetwork   = google_compute_subnetwork.docker_registry.self_link
  address_type = "INTERNAL"
  address      = cidrhost("10.90.1.0/24", 2)
  region       = var.region
}

resource "google_compute_health_check" "docker_registry" {
  name = "docker-registry-health-check${var.prefix}"

  timeout_sec        = 3
  check_interval_sec = 5

  https_health_check {
    port = 443
    request_path = "/"
  }
}

resource "google_compute_instance_template" "docker_registry" {
  name_prefix  = "docker-registry${var.prefix}-"
  machine_type = var.machine_type
  tags         = ["docker-registry", "${var.env}"]

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    disk_size_gb = var.cache_size_mb
    disk_type    = "pd-ssd"
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
  }

  network_interface {
    subnetwork    = google_compute_subnetwork.docker_registry.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    block-project-ssh-keys = "true"
    user-data              = "${data.template_file.cloud_config.rendered}"
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    scopes = [
      "monitoring-write",
      "monitoring-read",
      "monitoring",
      "cloud-platform"
    ]
  }
}

resource "google_compute_target_pool" "docker_registry" {
  name   = "docker-registry${var.prefix}"
  region = var.region
}

resource "google_compute_region_instance_group_manager" "docker_registry" {
  provider = google-beta

  base_instance_name        = "${var.env}-${var.index}-docker-registry"
  distribution_policy_zones = formatlist("${var.region}-%s", var.zones)
  name                      = "docker-registry${var.prefix}"
  region                    = var.region
  target_pools              = ["${google_compute_target_pool.docker_registry.self_link}"]
  target_size               = var.target_size

  version {
    name              = "default"
    instance_template = google_compute_instance_template.docker_registry.self_link
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_unavailable_fixed = "0"
    max_surge_fixed       = length(var.zones)
    min_ready_sec         = 900
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.docker_registry.self_link
    initial_delay_sec = 900
  }
}

resource "google_compute_region_backend_service" "docker_registry" {
  name             = "docker-registry-backend${var.prefix}"
  description      = "Backend servers for docker registry"
  protocol         = "TCP"
  session_affinity = "CLIENT_IP"
  timeout_sec      = 10
  region           = var.region

  backend {
    group = google_compute_region_instance_group_manager.docker_registry.instance_group
  }

  health_checks = ["${google_compute_health_check.docker_registry.self_link}"]
}

resource "google_compute_forwarding_rule" "docker_registry" {
  name                  = "docker-registry-forwarding${var.prefix}"
  backend_service       = google_compute_region_backend_service.docker_registry.self_link
  ip_address            = google_compute_address.docker_registry_frontend.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  region                = var.region
  network               = var.network
  ports                 = ["443"]
  subnetwork            = google_compute_subnetwork.docker_registry.self_link
}
