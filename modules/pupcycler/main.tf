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
  default = "v0.1.2"
}

resource "heroku_app" "pupcycler" {
  name   = "pupcycler-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    MANAGED_VIA                 = "github.com/travis-ci/terraform-config"
    PUPCYCLER_AUTH_TOKENS       = "${var.auth_token}"
    PUPCYCLER_ENVIRONMENT       = "${var.env}"
    PUPCYCLER_PACKET_AUTH_TOKEN = "${var.packet_auth_token}"
    PUPCYCLER_PACKET_PROJECT_ID = "${var.packet_project_id}"
    PUPCYCLER_POOL              = "${var.index}"
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
  --repo=travis-ci/pupcycler \
  --app=${heroku_app.pupcycler.id} \
  --ps-scale=${join(",", var.scale)} \
  --deploy-version=${var.version}
EOF
  }
}

output "web_url" {
  value = "${heroku_app.pupcycler.web_url}"
}
