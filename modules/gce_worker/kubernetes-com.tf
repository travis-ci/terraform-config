resource "kubernetes_secret" "worker_com_config" {
  metadata {
    name      = "worker-com-terraform"
    namespace = "${var.k8s_namespace}"
  }

  data = {
    TRAVIS_WORKER_GCE_ACCOUNT_JSON               = "${base64decode(google_service_account_key.workers_com.private_key)}"
    TRAVIS_WORKER_STACKDRIVER_TRACE_ACCOUNT_JSON = "${base64decode(google_service_account_key.workers_com.private_key)}"
    TRAVIS_WORKER_GCE_NETWORK                    = "${var.network_workers}"
    TRAVIS_WORKER_GCE_SUBNETWORK                 = "${var.subnetwork_workers}"
  }
}
