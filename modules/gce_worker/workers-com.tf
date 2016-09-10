data "template_file" "worker_cloud_init_com" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    account_json = "${var.account_json_com}"
    worker_config = "${var.config_com}"
    chef_json = "${var.chef_json_com}"
  }
}

resource "google_compute_instance" "worker_com" {
  count = "${var.instance_count}"
  name = "${var.env}-${var.index}-worker-com-${var.zone_suffix}-${count.index + 1}"
  machine_type = "${var.machine_type}"
  zone = "${var.zone}"
  tags = ["worker", "${var.env}", "com"]
  project = "${var.project}"

  disk {
    auto_delete = true
    image = "${var.worker_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "${var.subnetwork_com}"
  }

  metadata_startup_script = "${data.template_file.worker_cloud_init_com.rendered}"
}
