variable "auth_token" {}
variable "env" {}
variable "heroku_org" {}
variable "index" {}
variable "packet_auth_token" {}
variable "packet_project_id" {}

variable "redis_plan" {
  default = "premium-0"
}

variable "scale" {
  type    = "list"
  default = ["web=1:Standard-1X", "worker=1:Standard-1X"]
}

variable "syslog_address" {}

variable "version" {
  default = "master"
}

resource "heroku_app" "pupcycler" {
  name   = "pupcycler-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    PUPCYCLER_AUTH_TOKENS       = "${var.auth_token}"
    PUPCYCLER_PACKET_AUTH_TOKEN = "${var.packet_auth_token}"
    PUPCYCLER_PACKET_PROJECT_ID = "${var.packet_project_id}"
  }
}

resource "heroku_drain" "pupcycler_drain" {
  app = "${heroku_app.pupcycler.name}"
  url = "syslog+tls://${var.syslog_address}"
}

resource "heroku_addon" "pupcycler_redis" {
  app  = "${heroku_app.pupcycler.name}"
  plan = "heroku-redis:${var.redis_plan}"
}

resource "null_resource" "pupcycler" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.pupcycler.config_vars.0)))}"
    heroku_id        = "${heroku_app.pupcycler.id}"
    scale            = "${join(",", var.scale)}"
    version          = "${var.version}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/heroku-wait-deploy-scale \
  travis-ci/pupcycler \
  ${heroku_app.pupcycler.id} \
  ${join(",", var.scale)} \
  ${var.version}
EOF
  }
}

output "web_url" {
  value = "${heroku_app.pupcycler.web_url}"
}
