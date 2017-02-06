data "template_file" "cloud_init_env_org" {
  template = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "cloud_config_org" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"
  vars {
    cloud_init_bash = "${file("${path.module}/cloud-init.bash")}"
    cloud_init_env = "${data.template_file.cloud_init_env_org.rendered}"
    gce_account_json = "${var.account_json_org}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    syslog_address = "${var.syslog_address_org}"
    worker_config = "${var.config_org}"
  }
}

resource "google_compute_instance" "worker_org" {
  count = "${var.instance_count_org}"
  name = "${var.env}-${var.index}-worker-org-${var.zone_suffix}-${count.index + 1}"
  machine_type = "${var.machine_type}"
  zone = "${var.zone}"
  tags = ["worker", "${var.env}", "org"]
  project = "${var.project}"

  disk {
    auto_delete = true
    image = "${var.worker_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"
    access_config {
      # ephemeral ip
    }
  }

  # apparently not working :-/
  # maybe need to re-bake worker on top of a newer gce ubuntu image
  metadata {
    "block-project-ssh-keys" = "true"
    "user-data" = "${data.template_file.cloud_config_org.rendered}"
  }
}
