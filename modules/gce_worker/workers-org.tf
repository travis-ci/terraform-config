resource "google_compute_instance" "worker_org" {
  count = "${var.instance_count}"
  name = "${var.env}-worker-org-${var.gce_zone_suffix}-${count.index + 1}"
  machine_type = "${var.gce_machine_type}"
  zone = "${var.gce_zone}"
  tags = ["worker", "${var.env}", "org"]

  disk {
    auto_delete = true
    image = "${var.gce_worker_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "workersorg"
  }

  metadata_startup_script = "${file(format("cloud-init/travis-worker-gce-org-%s", var.env))}"
}
