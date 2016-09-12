resource "heroku_app" "gcloud_cleanup" {
  name = "gcloud-cleanup-${var.env}-${var.index}"
  region = "us"
  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    BUILDPACK_URL = "https://github.com/travis-ci/heroku-buildpack-makey-go"
    GCLOUD_CLEANUP_ACCOUNT_JSON = "${var.gcloud_cleanup_account_json}"
    GCLOUD_CLEANUP_ENTITIES = "instances"
    GCLOUD_CLEANUP_INSTANCE_MAX_AGE = "${var.gcloud_cleanup_instance_max_age}"
    GCLOUD_CLEANUP_JOB_BOARD_URL = "${var.gcloud_cleanup_job_board_url}"
    GCLOUD_CLEANUP_LOOP_SLEEP = "${var.gcloud_cleanup_loop_sleep}"
    GCLOUD_LOG_HTTP = "no-log-http"
    GCLOUD_PROJECT = "${var.project}"
    GCLOUD_ZONE = "${var.gcloud_zone}"
    GO_IMPORT_PATH = "github.com/travis-ci/gcloud-cleanup"
  }
}

resource "null_resource" "gcloud_cleanup" {
  triggers {
    heroku_id = "${heroku_app.gcloud_cleanup.id}"
    config_signature = "${sha256(join(",", values(heroku_app.gcloud_cleanup.config_vars.0)))}"
    ps_scale = "${var.gcloud_cleanup_scale}"
    version = "${var.gcloud_cleanup_version}"
  }

  provisioner "local-exec" {
    command = "exec ${path.module}/../../bin/heroku-wait-deploy-scale travis-ci/gcloud-cleanup ${heroku_app.gcloud_cleanup.id} ${var.gcloud_cleanup_scale} ${var.gcloud_cleanup_version}"
  }
}
