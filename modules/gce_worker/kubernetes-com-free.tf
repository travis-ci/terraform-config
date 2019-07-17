resource "kubernetes_secret" "worker_com_free_config" {
  metadata {
    name      = "worker-com-free-terraform"
    namespace = "${var.k8s_namespace}"
  }

  data = {
    TRAVIS_WORKER_GCE_ACCOUNT_JSON               = "${base64decode(google_service_account_key.workers_com_free.private_key)}"
    TRAVIS_WORKER_STACKDRIVER_TRACE_ACCOUNT_JSON = "${base64decode(google_service_account_key.workers_com_free.private_key)}"
    TRAVIS_WORKER_GCE_NETWORK                    = "main"
    TRAVIS_WORKER_GCE_SUBNETWORK                 = "jobs-com"
    TRAVIS_WORKER_AWS_ACCESS_KEY_ID              = "${var.aws_com_id}"
    TRAVIS_WORKER_AWS_SECRET_ACCESS_KEY          = "${var.aws_com_secret}"
    TRAVIS_WORKER_BUILD_TRACE_S3_BUCKET          = "${var.aws_com_trace_bucket}"
  }
}
