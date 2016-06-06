module "gce_project_0" {
    source = "../modules/gce_project"

    env = "${var.env}"

    gce_project = "travis-staging"
    gce_bastion_image = "${var.gce_bastion_image}"
    gce_worker_image = "${var.gce_worker_image}"

    cloud_init_org = "${template_file.cloud_init_org.rendered}"
    cloud_init_com = "${template_file.cloud_init_com.rendered}"
}
