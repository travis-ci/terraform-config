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
  name    = "${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.travisci.net"
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
    "${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.travisci.net",
  ]

  ip_addresses = [
    "${google_compute_address.addr.address}",
  ]

  subject {
    common_name  = "${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.travisci.net"
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
export TRAVIS_DOCKER_HOSTNAME=${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.travisci.net
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

resource "local_file" "client_cert" {
  content  = "${tls_locally_signed_cert.client.cert_pem}"
  filename = "${path.cwd}/config/docker-client-cert.pem"
}

resource "local_file" "client_key" {
  content  = "${tls_private_key.client.private_key_pem}"
  filename = "${path.cwd}/config/docker-client-key.pem"
}

resource "null_resource" "client_config" {
  triggers {
    ca_pem_signature      = "${sha256(var.docker_ca_pem)}"
    client_key_signature  = "${sha256(tls_private_key.client.private_key_pem)}"
    client_cert_signature = "${sha256(tls_locally_signed_cert.client.cert_pem)}"
  }

  provisioner "local-exec" {
    command = <<EOF
${path.module}/../../bin/generate-openssl-secret-cnf \
  ${random_id.client_secret.hex} \
  ${path.cwd}/config/ &&
${path.module}/../../bin/write-docker-client-config \
  --ca-pem ${path.cwd}/config/docker-ca.pem \
  --key-pem ${local_file.client_key.filename} \
  --cert-pem ${local_file.client_cert.filename} \
  --enc-config ${path.cwd}/config/ \
  --out ${path.cwd}/config/${var.env}-${var.index}-dockerd-${var.name}-client-config.tar.bz2.enc
EOF
  }

  depends_on = [
    "local_file.client_cert",
    "local_file.client_key",
  ]
}

data "aws_s3_bucket" "docker_client_configs" {
  bucket = "travis-docker-client-configs"
}

resource "aws_s3_bucket_object" "client_config" {
  key    = "${var.env}-${var.index}-dockerd-${var.name}-client-config.tar.bz2.enc"
  bucket = "${data.aws_s3_bucket.docker_client_configs.id}"
  source = "${path.cwd}/config/${var.env}-${var.index}-dockerd-${var.name}-client-config.tar.bz2.enc"

  acl = "public-read"

  depends_on = ["null_resource.client_config"]
}

resource "null_resource" "travis_env_assignment" {
  count = "${length(var.repos)}"

  triggers {
    ca_pem_signature        = "${sha256(var.docker_ca_pem)}"
    client_cert_signature   = "${sha256(tls_locally_signed_cert.client.cert_pem)}"
    client_config_signature = "${sha256("${aws_s3_bucket_object.client_config.bucket},${aws_s3_bucket_object.client_config.key}")}"
    client_key_signature    = "${sha256(tls_private_key.client.private_key_pem)}"
    repos_signature         = "${sha256(join(",", var.repos))}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-env-set-docker-config-secrets \
  --repository ${element(var.repos, count.index)} \
  --client-config-url https://s3.amazonaws.com/${aws_s3_bucket_object.client_config.bucket}/${aws_s3_bucket_object.client_config.key} \
  --docker-host tcp://${var.env}-${var.index}-dockerd-${var.name}.gce-${var.region}.travisci.net:2376 \
  --iv ${path.cwd}/config/openssl-iv \
  --key ${path.cwd}/config/openssl-key \
  --salt ${path.cwd}/config/openssl-salt
EOF
  }

  depends_on = ["null_resource.client_config"]
}
