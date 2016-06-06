module "gce_project_1" {
    source = "../modules/gce_project"

    env = "${var.env}"
    index = "1"

    gce_project = "travis-staging-1"
    gce_bastion_image = "${var.gce_bastion_image}"
    gce_worker_image = "${var.gce_worker_image}"

    cloud_init_org = "${template_file.cloud_init_org.rendered}"
    cloud_init_com = "${template_file.cloud_init_com.rendered}"
}

module "gce_project_2" {
    source = "../modules/gce_project"

    env = "${var.env}"
    index = "2"

    gce_project = "travis-staging-2"
    gce_bastion_image = "${var.gce_bastion_image}"
    gce_worker_image = "${var.gce_worker_image}"

    cloud_init_org = "${template_file.cloud_init_org.rendered}"
    cloud_init_com = "${template_file.cloud_init_com.rendered}"
}
