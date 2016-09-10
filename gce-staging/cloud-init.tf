data "template_file" "vault_consul_cloud_init" {
  template = "${file("${path.module}/vault-consul-init.tpl")}"

  vars {
    vault_consul_config = "${file("${path.module}/config/vault-consul-env")}"
  }
}
