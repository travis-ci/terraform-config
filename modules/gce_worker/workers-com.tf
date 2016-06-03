resource "google_compute_instance" "worker_com" {
  count = "${var.instance_count}"
  name = "${var.env}-worker-com-${var.gce_zone_suffix}-${count.index + 1}"
  machine_type = "${var.gce_machine_type}"
  zone = "${var.gce_zone}"
  tags = ["worker", "${var.env}", "com"]

  disk {
    auto_delete = true
    image = "${var.gce_worker_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "workerscom"
  }

  metadata_startup_script = "${var.cloud_init_com}"
}
