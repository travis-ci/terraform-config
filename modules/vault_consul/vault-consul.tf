resource "google_compute_instance" "vault_consul" {
  count = "${var.instance_count}"
  name = "${var.env}-${var.index}-vault-consul-${var.gce_zone_suffix}-${count.index + 1}"
  machine_type = "${var.gce_machine_type}"
  zone = "${var.gce_zone}"
  tags = ["vault", "consul", "${var.env}"]
  project = "${var.gce_project}"

  disk {
    auto_delete = true
    image = "${var.vault_consul_image}"
    type = "pd-ssd"
  }

  network_interface {
    subnetwork = "${var.gce_subnetwork}"
    access_config {
      # Ephemeral IP
    }
  }

  metadata_startup_script = "${var.cloud_init}"
}

resource "google_compute_firewall" "vault_firewall" {
  name = "allow-vault"
  description = "Allow access to Vault API from anywhere"
  network = "${var.gce_network}"
  project = "${var.gce_project}"

  allow {
    protocol = "tcp"
    ports = ["8200"]
  }

  target_tags = ["vault"]
  source_ranges = ["0.0.0.0/0"]
}