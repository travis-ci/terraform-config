resource "google_compute_address" "bastion" {
  count   = "${length(var.bastion_zones)}"
  name    = "bastion-${element(var.bastion_zones, count.index)}"
  region  = "${var.region}"
  project = "${var.project}"
}

resource "aws_route53_record" "bastion" {
  count   = "${length(var.bastion_zones)}"
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "bastion-${var.env}-${var.index}.gce-${var.region}-${element(var.bastion_zones, count.index)}.travisci.net"
  type    = "A"
  ttl     = 5

  records = [
    "${element(google_compute_address.bastion.*.address, count.index)}",
  ]
}

data "template_file" "bastion_cloud_config" {
  template = "${file("${path.module}/bastion-cloud-config.yml.tpl")}"

  vars {
    bastion_config  = "${var.bastion_config}"
    cloud_init_bash = "${file("${path.module}/bastion-cloud-init.bash")}"
    syslog_address  = "${var.syslog_address}"

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "google_compute_instance" "bastion" {
  count        = "${length(var.bastion_zones)}"
  name         = "${var.env}-${var.index}-bastion-${element(var.bastion_zones, count.index)}"
  machine_type = "g1-small"
  zone         = "${var.region}-${element(var.bastion_zones, count.index)}"
  tags         = ["bastion", "${var.env}"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.bastion_image}"
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.public.self_link}"

    access_config {
      nat_ip = "${element(google_compute_address.bastion.*.address, count.index)}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.bastion_cloud_config.rendered}"
  }
}
