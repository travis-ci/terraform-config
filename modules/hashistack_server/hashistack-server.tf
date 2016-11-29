resource "google_compute_instance" "hashistack_server" {
  count = "${var.instance_count}"
  name = "${var.env}-${var.index}-hashistack-server-${var.gce_zone_suffix}-${count.index + 1}"
  machine_type = "${var.gce_machine_type}"
  zone = "${var.gce_zone}"
  tags = [
    "vault",
    "consul",
    "consul-server",
    "nomad-server",
    "nomad",
    "${var.env}"
  ]
  project = "${var.gce_project}"

  disk {
    auto_delete = true
    image = "${var.hashistack_server_image}"
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
    ports = [8200]
  }

  target_tags = ["vault"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "consul_server_firewall" {
  name = "consul-server"
  description = "Allow Consul servers to talk to each other"
  network = "${var.gce_network}"
  project = "${var.gce_project}"

  allow {
    protocol = "tcp"
    ports = ["8301", "8302"]
  }

  allow {
    protocol = "udp"
    ports = ["8301", "8302"]
  }

  source_tags = ["consul-server"]
  target_tags = ["consul-server"]
}

resource "google_compute_firewall" "nomad_server_firewall" {
  name = "nomad-server"
  description = "Allow Nomad servers to talk to each other"
  network = "${var.gce_network}"
  project = "${var.gce_project}"

  allow {
    protocol = "tcp"
    ports = ["4647", "4648"]
  }

  allow {
    protocol = "udp"
    ports = ["4648"]
  }

  source_tags = ["nomad-server"]
  target_tags = ["nomad-server"]
}

resource "google_compute_firewall" "nomad_server_http" {
  name = "nomad-server-http"
  description = "Allow Nomad HTTP access from anyhere"
  network = "${var.gce_network}"
  project = "${var.gce_project}"

  allow {
    protocol = "tcp"
    ports = ["4646"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["nomad-server"]
}

output "hashistack_server_ip" { value = ["${google_compute_instance.hashistack_server.*.network_interface.0.access_config.0.assigned_nat_ip}"] }
