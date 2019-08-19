resource "kubernetes_namespace" "default" {
  metadata {
    name = "${var.default_namespace}"
  }
}

output "kubernetes_default_namespace" {
  value = "${kubernetes_namespace.default.metadata.name}"
}
