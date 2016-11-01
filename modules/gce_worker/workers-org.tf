data "template_file" "worker_cloud_init_org" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    account_json = "${var.account_json_org}"
    github_users = "${var.github_users}"
    worker_config = "${var.config_org}"
  }
}

resource "google_compute_instance" "worker_org" {
  count = "${var.instance_count}"
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
    subnetwork = "${var.subnetwork_org}"
  }

  metadata_startup_script = "${data.template_file.worker_cloud_init_org.rendered}"
}
