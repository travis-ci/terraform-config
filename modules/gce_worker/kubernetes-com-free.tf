resource "kubernetes_secret" "worker_com_free_config" {
  metadata {
    name      = "worker-com-free-terraform"
    namespace = "${var.k8s_namespace}"
  }

  data = {
    TRAVIS_WORKER_GCE_ACCOUNT_JSON               = "${base64decode(google_service_account_key.workers_com_free.private_key)}"
    TRAVIS_WORKER_STACKDRIVER_TRACE_ACCOUNT_JSON = "${base64decode(google_service_account_key.workers_com_free.private_key)}"
  }
}
