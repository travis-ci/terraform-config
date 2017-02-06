resource "google_compute_address" "bastion-b" {
  name = "bastion-b"
  region = "us-central1"
  project = "${var.project}"
}

resource "aws_route53_record" "bastion-b" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name = "bastion-${var.env}-${var.index}.gce-us-central1-b.travisci.net"
  type = "A"
  ttl = 5
  records = [
    "${google_compute_address.bastion-b.address}"
  ]
}

data "template_file" "bastion_cloud_init" {
  template = "${file("${path.module}/bastion-cloud-init.tpl")}"

  vars {
    bastion_config = "${var.bastion_config}"
    github_users = "${var.github_users}"
  }
}

resource "google_compute_instance" "bastion-b" {
  name = "${var.env}-${var.index}-bastion-b"
  machine_type = "g1-small"
  zone = "us-central1-b"
  tags = ["bastion", "${var.env}"]
  project = "${var.project}"

  disk {
    auto_delete = true
    image = "${var.bastion_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "public"
    access_config {
      nat_ip = "${google_compute_address.bastion-b.address}"
    }
  }

  metadata_startup_script = "${data.template_file.bastion_cloud_init.rendered}"
}
