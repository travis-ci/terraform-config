resource "google_compute_address" "nat" {
  count   = "${length(var.nat_zones) * var.nat_count_per_zone}"
  name    = "${var.nats_by_zone_prefix}${element(var.nat_names, count.index)}"
  region  = "${var.region}"
  project = "${var.project}"
}

resource "aws_route53_record" "nat" {
  count   = "${length(var.nat_zones) * var.nat_count_per_zone}"
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "${var.nats_by_zone_prefix}${element(var.nat_names, count.index)}.gce-${var.env}-${var.index}-${var.region}-${element(var.nat_zones, count.index / var.nat_count_per_zone)}.travisci.net"
  type    = "A"
  ttl     = 5

  records = ["${google_compute_address.nat.*.address[count.index]}"]
}

resource "aws_route53_record" "nat_regional" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat-${var.env}-${var.index}.gce-${var.region}.travisci.net"
  type    = "A"
  ttl     = 5

  records = ["${google_compute_address.nat.*.address}"]
}

resource "heroku_app" "nat_conntracker" {
  name   = "${var.nat_conntracker_name}-${var.env == "production" ? "prod" : var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    MANAGED_VIA = "github.com/travis-ci/terraform-config"
  }
}

resource "heroku_addon" "nat_conntracker_redis" {
  app  = "${heroku_app.nat_conntracker.name}"
  plan = "heroku-redis:${var.nat_conntracker_redis_plan}"
}

data "template_file" "nat_cloud_config" {
  template = "${file("${path.module}/nat-cloud-config.yml.tpl")}"

  vars {
    assets          = "${path.module}/../../../../assets"
    cloud_init_bash = "${file("${path.module}/nat-cloud-init.bash")}"
    nat_config      = "${var.nat_config}"
    syslog_address  = "${var.syslog_address}"

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    gesund_config = <<EOF
### in-line
export GESUND_SELF_IMAGE=${var.gesund_self_image}
EOF

    nat_conntracker_config = <<EOF
### nat-conntracker.env
${var.nat_conntracker_config}

### in-line
export NAT_CONNTRACKER_REDIS_ADDON_NAME=${heroku_addon.nat_conntracker_redis.name}
export NAT_CONNTRACKER_REDIS_APP_NAME=${heroku_app.nat_conntracker.name}
export NAT_CONNTRACKER_REDIS_URL=${lookup(heroku_app.nat_conntracker.all_config_vars, "REDIS_URL")}
export NAT_CONNTRACKER_SELF_IMAGE=${var.nat_conntracker_self_image}
EOF
  }
}

resource "google_compute_instance_template" "nat" {
  count          = "${length(var.nat_zones) * var.nat_count_per_zone}"
  name           = "${var.env}-${var.index}-${var.nats_by_zone_prefix}${element(var.nat_names, count.index)}-template-${substr(sha256("${var.nat_image}${data.template_file.nat_cloud_config.rendered}"), 0, 7)}"
  machine_type   = "${var.nat_machine_type}"
  can_ip_forward = true
  region         = "${var.region}"
  tags           = ["nat", "${var.env}"]
  project        = "${var.project}"

  labels {
    environment = "${var.env}"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = "${var.nat_image}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.public.self_link}"

    access_config {
      nat_ip = "${google_compute_address.nat.*.address[count.index]}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.nat_cloud_config.rendered}"
  }

  lifecycle {
    ignore_changes = ["*"]
    create_before_destroy = true
  }
}

resource "google_compute_http_health_check" "nat" {
  name                = "nat-health-check${var.nat_health_check_prefix}"
  request_path        = "/health-check"
  check_interval_sec  = 30
  healthy_threshold   = 1
  unhealthy_threshold = 5
  project             = "${var.project}"
}

resource "google_compute_firewall" "allow_nat_health_check" {
  name        = "allow-nat-health-check${var.nat_health_check_prefix}"
  network     = "${google_compute_network.main.name}"
  project     = "${var.project}"
  target_tags = ["nat"]

  source_ranges = ["${var.gce_health_check_source_ranges}"]

  allow {
    protocol = "tcp"
    ports    = [80]
  }
}

resource "google_compute_instance_group_manager" "nat" {
  provider = "google-beta"
  count    = "${length(var.nat_zones) * var.nat_count_per_zone}"

  base_instance_name = "${var.env}-${var.index}-${var.nats_by_zone_prefix}${element(var.nat_names, count.index)}"
  name               = "${var.nats_by_zone_prefix}${element(var.nat_names, count.index)}"
  target_size        = 1
  zone               = "${var.region}-${element(var.nat_zones, count.index)}"

  version {
    name              = "${var.env}-${var.index}-nat-default"
    instance_template = "${google_compute_instance_template.nat.*.self_link[count.index]}"
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = "${google_compute_http_health_check.nat.self_link}"
    initial_delay_sec = 300
  }
}

data "external" "nats_by_zone" {
  program = ["${path.module}/../../bin/gcloud-nats-by-zone"]

  query {
    zones   = "${join(",", var.nat_zones)}"
    region  = "${var.region}"
    project = "${var.project}"
    count   = "${length(var.nat_zones) * var.nat_count_per_zone}"
    prefix  = "${var.nats_by_zone_prefix}"
  }

  depends_on = ["google_compute_instance_group_manager.nat"]
}

resource "google_compute_route" "nat" {
  count                  = "${length(var.nat_zones) * var.nat_count_per_zone}"
  dest_range             = "0.0.0.0/0"
  name                   = "${var.nats_by_zone_prefix}${element(var.nat_names, count.index)}"
  network                = "${google_compute_network.main.self_link}"
  next_hop_instance      = "${data.external.nats_by_zone.result[var.nat_names[count.index]]}"
  next_hop_instance_zone = "${var.region}-${element(var.nat_zones, count.index / var.nat_count_per_zone)}"
  priority               = 800
  tags                   = ["no-ip"]
  project                = "${var.project}"

  lifecycle {
    # NOTE: the `next_hop_instance` is provided by `data.external.nats_by_zone`,
    # which does not play nicely with graph change detection.  Rather than
    # constantly re-creating these route resources, we ignore the change to
    # `next_hop_instance`.  Any changes in the instances within the relevant
    # instance groups will require a manual `taint` of *this* resource in order
    # for the route to correctly resolve.  See the following URL for details:
    # https://www.terraform.io/docs/commands/taint.html#example-tainting-a-resource-within-a-module
    ignore_changes = ["next_hop_instance"]
  }
}

data "template_file" "nat_rolling_updater_config" {
  template = <<EOF
export GCE_NAT_PROJECT='${var.project}'
export GCE_NAT_REGION='${var.region}'
export GCE_NAT_GROUPS='${join(",", google_compute_instance_group_manager.nat.*.name)}'
EOF
}

resource "local_file" "nat_rolling_updater_config" {
  content  = "${data.template_file.nat_rolling_updater_config.rendered}"
  filename = "${path.cwd}/config/nat-rolling-updater-${var.env}-${var.index}${var.nat_rolling_updater_config_prefix}.env"

  provisioner "local-exec" {
    command = "chmod 0644 ${local_file.nat_rolling_updater_config.filename}"
  }
}

resource "null_resource" "nat_conntracker_dynamic_config" {
  triggers {
    dst_ignore = "${sha256(join("", sort(var.nat_conntracker_dst_ignore)))}"
    src_ignore = "${sha256(join("", sort(var.nat_conntracker_src_ignore)))}"
  }

  provisioner "local-exec" {
    command = <<EOF
${path.module}/../../bin/nat-conntracker-configure \
    --app "${heroku_app.nat_conntracker.name}" \
    --dst-ignore "${join(",", sort(var.nat_conntracker_dst_ignore))}" \
    --src-ignore "${join(",", sort(var.nat_conntracker_src_ignore))}"
EOF
  }
}
