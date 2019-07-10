resource "kubernetes_namespace" "default" {
  metadata {
    name = "${var.k8s_default_namespace}"
  }
}
