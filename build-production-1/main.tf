variable "dockerd_image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1516675156-0b5be43"
}

variable "env" {
  default = "production"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "project" {
  default = "eco-emissary-99515"
}

variable "region" {
  default = "us-central1"
}

variable "repo" {
  default = "travis-ci/travis-build"
}

variable "syslog_address_com" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "zone" {
  default = "us-central1-f"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/build-production-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}

resource "random_id" "dockerd_org_client_secret" {
  byte_length = 32
}

resource "google_compute_address" "dockerd_org" {
  name    = "${var.env}-${var.index}-dockerd-org"
  region  = "${var.region}"
  project = "${var.project}"
}

resource "aws_route53_record" "dockerd_org" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "${var.env}-${var.index}-dockerd-org.gce-${var.region}.travisci.net"
  type    = "A"
  ttl     = 60

  records = ["${google_compute_address.dockerd_org.address}"]
}

resource "tls_private_key" "dockerd_org_server" {
  algorithm = "RSA"
}

resource "tls_private_key" "dockerd_org_client" {
  algorithm = "RSA"
}

resource "tls_cert_request" "dockerd_org_server" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.dockerd_org_server.private_key_pem}"

  dns_names = [
    "${var.env}-${var.index}-dockerd-org.gce-${var.region}.travisci.net",
  ]

  ip_addresses = [
    "${google_compute_address.dockerd_org.address}",
  ]

  subject {
    common_name  = "${var.env}-${var.index}-dockerd-org.gce-${var.region}.travisci.net"
    organization = "Travis CI GmbH"
  }
}

resource "tls_cert_request" "dockerd_org_client" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.dockerd_org_client.private_key_pem}"

  subject {
    common_name = "client"
  }
}

resource "tls_locally_signed_cert" "dockerd_org_server" {
  cert_request_pem   = "${tls_cert_request.dockerd_org_server.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${file("config/docker-ca-key.pem")}"
  ca_cert_pem        = "${file("config/docker-ca.pem")}"

  validity_period_hours = 87600

  allowed_uses = [
    "server_auth",
  ]
}

resource "tls_locally_signed_cert" "dockerd_org_client" {
  cert_request_pem   = "${tls_cert_request.dockerd_org_client.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${file("config/docker-ca-key.pem")}"
  ca_cert_pem        = "${file("config/docker-ca.pem")}"

  validity_period_hours = 87600

  allowed_uses = [
    "client_auth",
  ]
}

data "template_file" "dockerd_org_cloud_config" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    here = "${path.module}"

    docker_server_key_pem  = "${tls_private_key.dockerd_org_server.private_key_pem}"
    docker_server_cert_pem = "${tls_locally_signed_cert.dockerd_org_server.cert_pem}"

    docker_config = <<EOF
### docker.env
${file("${path.module}/docker.env")}

### in-line
export TRAVIS_DOCKER_HOSTNAME=${var.env}-${var.index}-dockerd-org.gce-${var.region}.travisci.net
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF

    syslog_address = "${var.syslog_address_com}"
  }
}

resource "google_compute_disk" "dockerd_org" {
  name = "${var.env}-${var.index}-dockerd-lvm"
  type = "pd-ssd"
  zone = "${var.zone}"
  size = 500

  labels {
    environment = "${var.env}"
    site        = "org"
  }
}

resource "google_compute_instance" "dockerd_org" {
  name = "${var.env}-${var.index}-dockerd-org"

  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["dockerd", "${var.env}"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.dockerd_image}"
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source = "${google_compute_disk.dockerd_org.self_link}"
  }

  network_interface {
    subnetwork = "public"

    access_config {
      nat_ip = "${google_compute_address.dockerd_org.address}"
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.dockerd_org_cloud_config.rendered}"
  }
}

resource "local_file" "dockerd_org_client_cert" {
  content  = "${tls_locally_signed_cert.dockerd_org_client.cert_pem}"
  filename = "${path.module}/config/docker-client-cert.pem"
}

resource "local_file" "dockerd_org_client_key" {
  content  = "${tls_private_key.dockerd_org_client.private_key_pem}"
  filename = "${path.module}/config/docker-client-key.pem"
}

resource "null_resource" "dockerd_org_client_config" {
  triggers {
    ca_pem_signature      = "${sha256(file("config/docker-ca.pem"))}"
    client_key_signature  = "${sha256(tls_private_key.dockerd_org_client.private_key_pem)}"
    client_cert_signature = "${sha256(tls_locally_signed_cert.dockerd_org_client.cert_pem)}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/generate-openssl-secret-cnf \
  ${random_id.dockerd_org_client_secret.hex} \
  ${path.module}/config/
EOF
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/write-docker-client-config \
  --ca-pem ${path.module}/config/docker-ca.pem \
  --key-pem ${local_file.dockerd_org_client_key.filename} \
  --cert-pem ${local_file.dockerd_org_client_cert.filename} \
  --enc-config ${path.module}/config/ \
  --out ${path.module}/config/${var.env}-${var.index}-dockerd-org-client-config.tar.bz2.enc
EOF
  }

  depends_on = [
    "local_file.dockerd_org_client_cert",
    "local_file.dockerd_org_client_key",
  ]
}

resource "aws_s3_bucket" "docker_client_configs" {
  bucket = "travis-docker-client-configs"
  acl    = "public-read"
}

data "local_file" "dockerd_org_client_config" {
  filename   = "${path.module}/config/${var.env}-${var.index}-dockerd-org-client-config.tar.bz2.enc"
  depends_on = ["null_resource.dockerd_org_client_config"]
}

resource "aws_s3_bucket_object" "dockerd_org_client_config" {
  key    = "${var.env}-${var.index}-dockerd-org-client-config.tar.bz2"
  bucket = "${aws_s3_bucket.docker_client_configs.id}"
  source = "${path.module}/config/${var.env}-${var.index}-dockerd-org-client-config.tar.bz2.enc"

  acl = "public-read"

  depends_on = ["null_resource.dockerd_org_client_config"]
}

resource "null_resource" "dockerd_org_travis_env_assignment" {
  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/assign-docker-config-travis-env-secrets \
  --repository ${var.repo} \
  --iv ${path.module}/config/openssl-iv \
  --key ${path.module}/config/openssl-key \
  --salt ${path.module}/config/openssl-salt
EOF
  }

  depends_on = ["null_resource.dockerd_org_client_config"]
}
