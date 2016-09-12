module "gce_worker_b" {
  source = "../gce_worker"

  account_json_com = "${var.worker_account_json_com}"
  account_json_org = "${var.worker_account_json_org}"
  config_com = "${var.worker_config_com}"
  config_org = "${var.worker_config_org}"
  env = "${var.env}"
  index = "${var.index}"
  instance_count = "1"
  machine_type = "g1-small"
  project = "${var.project}"
  subnetwork_com = "${google_compute_subnetwork.workers_com.name}"
  subnetwork_org = "${google_compute_subnetwork.workers_org.name}"
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
  index = "${var.index}"
  instance_count = "1"
  machine_type = "g1-small"
  project = "${var.project}"
  subnetwork_com = "${google_compute_subnetwork.workers_com.name}"
  subnetwork_org = "${google_compute_subnetwork.workers_org.name}"
  worker_image = "${var.worker_image}"
  zone = "us-central1-c"
  zone_suffix = "c"
}
