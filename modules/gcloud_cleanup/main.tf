resource "random_id" "client_secret" {
  byte_length = 32
}

resource "google_compute_address" "addr" {
  name   = "${var.env}-${var.index}-dockerd-${var.name}"
  region = "${var.region}"
}

data "aws_route53_zone" "travisci_net" {
  name = "${var.dns_domain}."
}

resource "google_service_account" "gcloud_cleanup" {
  account_id   = "gcloud-cleanup-gpc"
  display_name = "Gcloud Cleanup on gpc"
  project      = "${var.project}"
}

resource "google_service_account_key" "gcloud_cleanup" {
  service_account_id = "${google_service_account.gcloud_cleanup.email}"
}

resource "google_storage_bucket" "gcloud_cleanup_archive" {
  name    = "gcloud-cleanup-new-${var.env}-${var.index}"
  project = "${var.project}"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = "${var.gcloud_cleanup_archive_retention_days}"
    }
  }
}

resource "aws_route53_record" "a_rec" {
  zone_id = "${data.aws_route53_zone.travisci_net.zone_id}"
  name    = "${var.env}-${var.index}-gcloud-cleanup-${var.name}.gce-${var.region}.${var.dns_domain}"
  type    = "A"
  ttl     = 60

  records = ["${google_compute_address.addr.address}"]
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    here = "${path.module}"

    gce_account_json = "${base64decode(google_service_account_key.gcloud_cleanup.private_key)}"

    gcloud_cleanup_config = <<EOF
export GCLOUD_CLEANUP_RATE_LIMIT_REDIS_URL=${var.google_redis_instance}
export GCLOUD_CLEANUP_RATE_LIMIT_PREFIX=gcloud-cleanup

export BUILDPACK_URL="https://github.com/travis-ci/heroku-buildpack-makey-go"
export GCLOUD_CLEANUP_ACCOUNT_JSON="/var/tmp/gce.json"
export GCLOUD_CLEANUP_ARCHIVE_BUCKET="${google_storage_bucket.gcloud_cleanup_archive.name}"
export GCLOUD_CLEANUP_ARCHIVE_SERIAL="true"
export GCLOUD_CLEANUP_ARCHIVE_SAMPLE_RATE="10"
export GCLOUD_CLEANUP_ENTITIES="instances"
export GCLOUD_CLEANUP_INSTANCE_MAX_AGE="${var.gcloud_cleanup_instance_max_age}"
export GCLOUD_CLEANUP_JOB_BOARD_URL="${var.gcloud_cleanup_job_board_url}"
export GCLOUD_CLEANUP_LOOP_SLEEP="${var.gcloud_cleanup_loop_sleep}"
export GCLOUD_CLEANUP_OPENCENSUS_SAMPLING_RATE="${var.gcloud_cleanup_opencensus_sampling_rate}"
export GCLOUD_CLEANUP_OPENCENSUS_TRACING_ENABLED="${var.gcloud_cleanup_opencensus_tracing_enabled}"
export GCLOUD_LOG_HTTP="no-log-http"
export GCLOUD_PROJECT="${var.project}"
export GCLOUD_ZONE="${var.gcloud_zone}"
export GO_IMPORT_PATH="github.com/travis-ci/gcloud-cleanup"
export MANAGED_VIA="github.com/travis-ci/terraform-config"
export GCLOUD_CLEANUP_INSTANCE_FILTERS="${base64encode(var.gcloud_cleanup_instance_filters)}"
EOF

    cloud_init_env = <<EOF
export TRAVIS_GCLOUD_CLEANUP_SELF_IMAGE="${var.gcloud_cleanup_docker_self_image}"
EOF

    docker_config = <<EOF
${file("${path.module}/docker.env")}

EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF

    syslog_address = "${var.syslog_address}"
  }
}

resource "google_compute_autoscaler" "gcloud-cleanup" {
  name   = "${var.env}-${var.index}-gcloud-cleanup-${var.name}-autoscaler"
  zone   = "${var.zone}"
  target = "${google_compute_instance_group_manager.gcloud-cleanup.self_link}"

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 180

    cpu_utilization {
      target = 1
    }
  }
}

resource "google_compute_instance_template" "gcloud-cleanup" {
  name_prefix    = "${var.env}-${var.index}-gcloud-cleanup-template-"
  machine_type   = "${var.machine_type}"
  can_ip_forward = false

  tags = ["gcloud-cleanup", "${var.env}"]

  disk {
    source_image = "${var.image}"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  network_interface {
    subnetwork = "${var.subnetwork}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config.rendered}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_pool" "gcloud-cleanup" {
  name = "${var.env}-${var.index}-gcloud-cleanup-${var.name}-target-pool"
}

resource "google_compute_instance_group_manager" "gcloud-cleanup" {
  name = "${var.env}-${var.index}-gcloud-cleanup-${var.name}-igm"
  zone = "${var.zone}"

  instance_template = "${google_compute_instance_template.gcloud-cleanup.self_link}"

  target_pools       = ["${google_compute_target_pool.gcloud-cleanup.self_link}"]
  base_instance_name = "${var.env}-${var.index}-gcloud-cleanup"
}
