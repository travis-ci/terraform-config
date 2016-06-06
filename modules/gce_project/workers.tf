module "gce_worker_b" {
    source = "../gce_worker"

    env = "${var.env}"
    instance_count = "1"

    gce_project = "${var.gce_project}"
    gce_zone = "us-central1-b"
    gce_zone_suffix = "b"

    gce_machine_type = "g1-small"
    gce_worker_image = "${var.gce_worker_image}"

    subnetwork_org = "${google_compute_subnetwork.workers_org.name}"
    subnetwork_com = "${google_compute_subnetwork.workers_com.name}"

    cloud_init_org = "${var.cloud_init_org}"
    cloud_init_com = "${var.cloud_init_com}"
}

module "gce_worker_c" {
    source = "../gce_worker"

    env = "${var.env}"
    instance_count = "1"

    gce_project = "${var.gce_project}"
    gce_zone = "us-central1-c"
    gce_zone_suffix = "c"

    gce_machine_type = "g1-small"
    gce_worker_image = "${var.gce_worker_image}"

    subnetwork_org = "${google_compute_subnetwork.workers_org.name}"
    subnetwork_com = "${google_compute_subnetwork.workers_com.name}"

    cloud_init_org = "${var.cloud_init_org}"
    cloud_init_com = "${var.cloud_init_com}"
}
