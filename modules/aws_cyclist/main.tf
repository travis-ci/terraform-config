variable "cyclist_auth_token" {}

variable "cyclist_aws_region" {
  default = "us-east-1"
}

variable "cyclist_debug" {
  default = "false"
}

variable "cyclist_redis_plan" {
  default = "premium-0"
}

variable "cyclist_scale" {
  default = "web=1:Standard-1X"
}

variable "cyclist_token_ttl" {
  default = "1h"
}

variable "cyclist_version" {
  default = "master"
}

variable "env" {}

variable "heroku_org" {}
variable "index" {}

variable "site" {}
variable "syslog_address" {}

resource "aws_iam_user" "cyclist" {
  name = "cyclist-${var.env}-${var.index}-${var.site}"
}

resource "aws_iam_access_key" "cyclist" {
  user       = "${aws_iam_user.cyclist.name}"
  depends_on = ["aws_iam_user.cyclist"]
}

resource "aws_iam_user_policy" "cyclist_actions" {
  name = "cyclist_actions_${var.env}_${var.index}_${var.site}"
  user = "${aws_iam_user.cyclist.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sns:*",
        "autoscaling:*",
        "cloudwatch:PutMetricAlarm",
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

  depends_on = ["aws_iam_user.cyclist"]
}

resource "heroku_app" "cyclist" {
  name   = "cyclist-${var.env}-${var.index}-${var.site}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    AWS_ACCESS_KEY      = "${aws_iam_access_key.cyclist.id}"
    AWS_REGION          = "${var.cyclist_aws_region}"
    AWS_SECRET_KEY      = "${aws_iam_access_key.cyclist.secret}"
    BUILDPACK_URL       = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    CYCLIST_AUTH_TOKENS = "${var.cyclist_auth_token}"
    CYCLIST_DEBUG       = "${var.cyclist_debug}"
    CYCLIST_TOKEN_TTL   = "${var.cyclist_token_ttl}"
    GO_IMPORT_PATH      = "github.com/travis-ci/cyclist"
    MANAGED_VIA         = "github.com/travis-ci/terraform-config"
  }
}

resource "heroku_drain" "cyclist_drain" {
  app = "${heroku_app.cyclist.name}"
  url = "syslog+tls://${var.syslog_address}"
}

resource "heroku_addon" "cyclist_redis" {
  app  = "${heroku_app.cyclist.name}"
  plan = "heroku-redis:${var.cyclist_redis_plan}"
}

resource "null_resource" "cyclist" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.cyclist.config_vars.0)))}"
    heroku_id        = "${heroku_app.cyclist.id}"
    ps_scale         = "${var.cyclist_scale}"
    version          = "${var.cyclist_version}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/heroku-wait-deploy-scale \
  --repo=travis-ci/cyclist \
  --app=${heroku_app.cyclist.id} \
  --ps-scale=${var.cyclist_scale} \
  --deploy-version=${var.cyclist_version}
EOF
  }
}

output "cyclist_url" {
  value = "${replace(heroku_app.cyclist.web_url, "/\\/$/", "")}"
}
