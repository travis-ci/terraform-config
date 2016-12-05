module "gce_worker_b" {
  source = "../gce_worker"

  account_json_com = "${var.worker_account_json_com}"
  account_json_org = "${var.worker_account_json_org}"
  config_com = "${var.worker_config_com}"
  config_org = "${var.worker_config_org}"
  env = "${var.env}"
  github_users = "${var.github_users}"
  index = "${var.index}"
  instance_count = 1
  machine_type = "g1-small"
  project = "${var.project}"
  subnetwork_workers = "${google_compute_subnetwork.workers.name}"
  syslog_address_com = "${var.syslog_address_com}"
  syslog_address_org = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image = "${var.worker_image}"
  zone = "us-central1-b"
  zone_suffix = "b"
}

module "gce_worker_c" {
  source = "../gce_worker"

  account_json_com = "${var.worker_account_json_com}"
  account_json_org = "${var.worker_account_json_org}"
  config_com = "${var.worker_config_com}"
  config_org = "${var.worker_config_org}"
  env = "${var.env}"
  github_users = "${var.github_users}"
  index = "${var.index}"
  instance_count = 1
  machine_type = "g1-small"
  project = "${var.project}"
  subnetwork_workers = "${google_compute_subnetwork.workers.name}"
  syslog_address_com = "${var.syslog_address_com}"
  syslog_address_org = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image = "${var.worker_image}"
  zone = "us-central1-c"
  zone_suffix = "c"
}
