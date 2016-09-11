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
    GO_BINARY_URL = "https://s3.amazonaws.com/travis-ci-gcloud-cleanup-artifacts/travis-ci/gcloud-cleanup/$SOURCE_VERSION/build.tar.gz"
    GO_IMPORT_PATH = "github.com/travis-ci/gcloud-cleanup"
  }
}
