

resource "ibm_is_volume" "icp-instances-vol" {
    count    = "${var.workers}"
    name     = "${var.basename}-instances-worker${count.index+1}-com"
    profile  = "general-purpose"
    zone     = "${var.ibmcloud_zone}"
    capacity = "250"
}

resource "ibm_is_volume" "icp-instances-vol-org" {
    count    = "${var.workers_org}"
    name     = "${var.basename}-instances-worker${count.index+1}-org"
    profile  = "general-purpose"
    zone     = "${var.ibmcloud_zone}"
    capacity = "250"
}

data "template_file" "worker" {
  template = "${file("../modules/ibm_worker/tpl/worker.sh.tpl")}"

  vars = {
    PATH                                 = "$PATH"
    PAPERTRAIL_PORT                      = "48398"
    SALT_MASTER                          = "${var.salt_master}"
    POOL_SIZE                            = "8"
    TRAVIS_WORKER_AMQP_URI               = "${var.travis_worker["amqp_uri"]}"
    TRAVIS_WORKER_BUILD_API_URI          = "${var.travis_worker["build_api_uri"]}"
    TRAVIS_WORKER_PROVIDER_NAME          = "${var.travis_worker["provider_name"]}"
    TRAVIS_WORKER_QUEUE_NAME             = "${var.travis_worker["queue_name"]}"
    TRAVIS_WORKER_LXD_DISK               = "${var.travis_worker["lxd_disk"]}"
    TRAVIS_WORKER_LXD_IMAGE_SELECTOR_URL = "${var.travis_worker["lxd_image_selector_url"]}"

    TRAVIS_WORKER_LIBRATO_SOURCE = "$(hostname)"
    TRAVIS_WORKER_LIBRATO_EMAIL  = "${var.travis_worker["librato_email"]}"
    TRAVIS_WORKER_LIBRATO_TOKEN  = "${var.travis_worker["librato_token"]}"
  }
}

data "template_file" "worker-org" {
  template = "${file("../modules/ibm_worker/tpl/worker.sh.tpl")}"

  vars = {
    PATH                                 = "$PATH"
    PAPERTRAIL_PORT                      = "48398"
    SALT_MASTER                          = "${var.salt_master}"
    POOL_SIZE                            = "8"
    TRAVIS_WORKER_AMQP_URI               = "${var.travis_worker_org["amqp_uri"]}"
    TRAVIS_WORKER_BUILD_API_URI          = "${var.travis_worker_org["build_api_uri"]}"
    TRAVIS_WORKER_PROVIDER_NAME          = "${var.travis_worker_org["provider_name"]}"
    TRAVIS_WORKER_QUEUE_NAME             = "${var.travis_worker_org["queue_name"]}"
    TRAVIS_WORKER_LXD_DISK               = "${var.travis_worker_org["lxd_disk"]}"
    TRAVIS_WORKER_LXD_IMAGE_SELECTOR_URL = "${var.travis_worker_org["lxd_image_selector_url"]}"

    TRAVIS_WORKER_LIBRATO_SOURCE = "$(hostname)"
    TRAVIS_WORKER_LIBRATO_EMAIL  = "${var.travis_worker_org["librato_email"]}"
    TRAVIS_WORKER_LIBRATO_TOKEN  = "${var.travis_worker_org["librato_token"]}"
  }
}

resource "ibm_is_instance" "worker" {
    count   = "${var.workers}"
    name    = "lxd-ppc64le-${var.basename}-worker${count.index+1}-com"
    image   = "${var.image_id}"
    profile = "${var.profile_id}"

    primary_network_interface = {
        subnet = "${var.subnet_id}"
    }

    vpc  = "${var.vpc_id}"
    zone = "${var.ibmcloud_zone}"
    keys = ["${var.public_key_id}"]

    timeouts {
        create = "90m"
        delete = "30m"
    }

    volumes = [
      "${element(ibm_is_volume.icp-instances-vol.*.id, count.index)}"
    ]

    lifecycle {
        ignore_changes = ["user_data"]
    }

    user_data = "${data.template_file.worker.rendered}"
}

resource "ibm_is_instance" "worker-org" {
    count   = "${var.workers_org}"
    name    = "lxd-ppc64le-${var.basename}-worker${count.index+1}-org"
    image   = "${var.image_id}"
    profile = "${var.profile_id}"

    primary_network_interface = {
        subnet = "${var.subnet_id}"
    }

    vpc  = "${var.vpc_id}"
    zone = "${var.ibmcloud_zone}"
    keys = ["${var.public_key_id}"]

    timeouts {
        create = "90m"
        delete = "30m"
    }

    volumes = [
      "${element(ibm_is_volume.icp-instances-vol-org.*.id, count.index)}"
    ]

    lifecycle {
        ignore_changes = ["user_data"]
    }

    user_data = "${data.template_file.worker-org.rendered}"
}

#resource "ibm_is_floating_ip" "worker" {
#    depends_on = ["ibm_is_instance.worker"]
#    count  = "${var.workers}"
#    name   = "${var.basename}-worker${count.index+1}"
#    target = "${element(ibm_is_instance.worker.*.primary_network_interface.0.id, count.index)}"
#}
