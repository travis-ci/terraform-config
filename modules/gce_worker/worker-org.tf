data "template_file" "cloud_config_org" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../../../assets"
    gce_account_json = "${base64decode(google_service_account_key.workers_org.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_org}"

    worker_config = <<EOF
${var.config_org}
export TRAVIS_WORKER_GCE_RATE_LIMIT_REDIS_URL=redis://${google_redis_instance.worker_rate_limit.host}:${google_redis_instance.worker_rate_limit.port}
EOF

    cloud_init_env = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "null_resource" "worker_org_validation" {
  triggers {
    config_signature = "${sha256(data.template_file.cloud_config_org.rendered)}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-worker-verify-config \
  "${base64encode(data.template_file.cloud_config_org.rendered)}"
EOF
  }
}

resource "google_compute_instance_template" "worker_org" {
  name_prefix = "${var.env}-${var.index}-worker-org-"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "org"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "${var.worker_image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  service_account {
    email = "${google_service_account.workers_org.email}"

    scopes = [
      "cloud-platform",
      "storage-full",
      "compute-rw",
      "trace-append",
    ]
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_org.rendered}"
  }

  depends_on = ["null_resource.worker_org_validation"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "worker_org" {
  base_instance_name = "${var.env}-${var.index}-worker-org-gce"
  instance_template  = "${google_compute_instance_template.worker_org.self_link}"
  name               = "worker-org"
  target_size        = "${var.managed_instance_count_org}"
  update_strategy    = "NONE"
  region             = "${var.region}"

  distribution_policy_zones = "${formatlist("${var.region}-%s", var.zones)}"
}
