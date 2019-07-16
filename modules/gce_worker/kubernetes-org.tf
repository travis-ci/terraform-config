resource "kubernetes_secret" "worker_org_config" {
  metadata {
    name      = "worker-org-terraform"
    namespace = "${var.k8s_namespace}"
  }

  data = {
    TRAVIS_WORKER_GCE_ACCOUNT_JSON               = "${base64decode(google_service_account_key.workers_org.private_key)}"
    TRAVIS_WORKER_STACKDRIVER_TRACE_ACCOUNT_JSON = "${base64decode(google_service_account_key.workers_org.private_key)}"
    TRAVIS_WORKER_GCE_NETWORK                    = "main"
    TRAVIS_WORKER_GCE_SUBNETWORK                 = "jobs-org"
  }
}
