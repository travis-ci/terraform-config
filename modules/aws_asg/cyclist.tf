resource "heroku_app" "cyclist" {
  name = "cyclist-${var.site}-${var.env}-${var.index}"
  region = "us"
  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    AWS_ACCESS_KEY = "${aws_iam_access_key.cyclist.id}"
    AWS_REGION = "${var.cyclist_aws_region}"
    AWS_SECRET_KEY = "${aws_iam_access_key.cyclist.secret}"
    BUILDPACK_URL = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    CYCLIST_AUTH_TOKENS = "${var.cyclist_auth_tokens}"
    CYCLIST_DEBUG = "${var.cyclist_debug}"
    GO_IMPORT_PATH = "github.com/travis-ci/cyclist"
  }
}

resource "heroku_drain" "cyclist_drain" {
  app = "${heroku_app.cyclist.name}"
  url = "syslog://${var.syslog_address}"
}

resource "heroku_addon" "cyclist_redis" {
  app = "${heroku_app.cyclist.name}"
  plan = "heroku-redis:${var.cyclist_redis_plan}"
}

resource "null_resource" "cyclist" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.cyclist.config_vars.0)))}"
    heroku_id = "${heroku_app.cyclist.id}"
    ps_scale = "${var.cyclist_scale}"
    version = "${var.cyclist_version}"
  }

  provisioner "local-exec" {
    command = "exec ${path.module}/../../bin/heroku-wait-deploy-scale travis-ci/cyclist ${heroku_app.cyclist.id} ${var.cyclist_scale} ${var.cyclist_version}"
  }
}
