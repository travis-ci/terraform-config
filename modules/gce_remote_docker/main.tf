variable "client_config_bucket" {
  default = "travis-docker-client-configs"
}

variable "docker_ca_key_pem" {}
variable "docker_ca_pem" {}
variable "env" {}
variable "github_users" {}

variable "image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1516675156-0b5be43"
}

variable "index" {}
variable "name" {}

variable "region" {
  default = "us-central1"
}

variable "repos" {
  type = "list"
}

variable "syslog_address" {}

variable "zone" {
  default = "us-central1-f"
}

resource "random_id" "client_secret" {
  byte_length = 32
}

resource "google_compute_address" "addr" {
  name   = "${var.env}-${var.index}-dockerd-${var.name}"
  region = "${var.region}"
}

data "aws_route53_zone" "travisci_net" {
  name = "travisci.net."
}

resource "aws_route53_record" "a_rec" {
  zone_id = "${data.aws_route53_zone.travisci_net.zone_id}"
  name    = "${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.${data.aws_route53_zone.travisci_net.name}"
  type    = "A"
  ttl     = 60

  records = ["${google_compute_address.addr.address}"]
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
}

resource "tls_private_key" "client" {
  algorithm = "RSA"
}

resource "tls_cert_request" "server" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.server.private_key_pem}"

  dns_names = [
    "${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.${data.aws_route53_zone.travisci_net.name}",
  ]

  ip_addresses = [
    "${google_compute_address.addr.address}",
  ]

  subject {
    common_name  = "${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.${data.aws_route53_zone.travisci_net.name}"
    organization = "Travis CI GmbH"
  }
}

resource "tls_cert_request" "client" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.client.private_key_pem}"

  subject {
    common_name = "client"
  }
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = "${tls_cert_request.server.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${var.docker_ca_key_pem}"
  ca_cert_pem        = "${var.docker_ca_pem}"

  validity_period_hours = 87600

  allowed_uses = [
    "server_auth",
  ]
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = "${tls_cert_request.client.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${var.docker_ca_key_pem}"
  ca_cert_pem        = "${var.docker_ca_pem}"

  validity_period_hours = 87600

  allowed_uses = [
    "client_auth",
  ]
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    here = "${path.module}"

    docker_ca_pem          = "${var.docker_ca_pem}"
    docker_server_key_pem  = "${tls_private_key.server.private_key_pem}"
    docker_server_cert_pem = "${tls_locally_signed_cert.server.cert_pem}"

    docker_config = <<EOF
### docker.env
${file("${path.module}/docker.env")}

### in-line
export TRAVIS_DOCKER_HOSTNAME=${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.${data.aws_route53_zone.travisci_net.name}
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF

    syslog_address = "${var.syslog_address}"
  }
}

resource "google_compute_disk" "lvm" {
  name = "${var.env}-${var.index}-dockerd-lvm"
  type = "pd-ssd"
  zone = "${var.zone}"
  size = 500

  labels {
    environment = "${var.env}"
    name        = "${var.name}"
  }
}

resource "google_compute_instance" "instance" {
  name = "${var.env}-${var.index}-dockerd-${var.name}"

  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["dockerd", "${var.env}"]

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.image}"
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source = "${google_compute_disk.lvm.self_link}"
  }

  network_interface {
    subnetwork = "public"

    access_config {
      nat_ip = "${google_compute_address.addr.address}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config.rendered}"
  }
}

data "archive_file" "client_config" {
  type        = "zip"
  output_path = "${path.cwd}/config/${var.env}-${var.index}-docker-${var.name}-client-config.zip"

  source {
    content  = "${tls_locally_signed_cert.client.cert_pem}"
    filename = ".docker/cert.pem"
  }

  source {
    content  = "${tls_private_key.client.private_key_pem}"
    filename = ".docker/key.pem"
  }

  source {
    content  = "${path.cwd}/config/docker-ca.pem"
    filename = ".docker/ca.pem"
  }
}

resource "google_service_account" "client_config_signer" {
  account_id   = "${var.env}-${var.index}-docker-${var.name}"
  display_name = "Docker Client Config signer"
}

resource "google_service_account_key" "client_config_signer" {
  service_account_id = "${google_service_account.client_config_signer.name}"
}

resource "google_storage_bucket_object" "client_config" {
  name   = "${var.env}-${var.index}-docker-${var.name}-client-config.zip"
  source = "${path.cwd}/config/${var.env}-${var.index}-docker-${var.name}-client-config.zip"
  bucket = "${var.client_config_bucket}"
}

data "google_storage_object_signed_url" "client_config" {
  bucket      = "${var.client_config_bucket}"
  path        = "${var.env}-${var.index}-docker-${var.name}-client-config.zip"
  duration    = "8760h"
  credentials = "${base64decode(google_service_account_key.client_config_signer.private_key)}"
}

resource "null_resource" "travis_env_assignment" {
  count = "${length(var.repos)}"

  triggers {
    client_config_url_signature = "${sha256("${data.google_storage_object_signed_url.client_config.signed_url}")}"
    repos_signature             = "${sha256(join(",", var.repos))}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-env-set-docker-config-secrets \
  --repository ${element(var.repos, count.index)} \
  --client-config-url '${data.google_storage_object_signed_url.client_config.signed_url}' \
  --docker-host tcp://${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.${data.aws_route53_zone.travisci_net.name}:2376 \
EOF
  }
}
