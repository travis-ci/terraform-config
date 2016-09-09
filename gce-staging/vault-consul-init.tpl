#!/usr/bin/env bash

set -o errexit

main() {
  ${vault_consul_config}
  export GCE_VAULT_CONSUL_CONSUL_ENCRYPTION_KEY GCE_VAULT_CONSUL_CONSUL_BOOTSTRAP_EXPECT GCE_VAULT_CONSUL_VAULT_TLS_CERT GCE_VAULT_CONSUL_VAULT_TLS_KEY
  __write_consul_config
  __restart_consul
  __write_vault_config
  __restart_vault
}

__write_consul_config() {
    mkdir /opt/consul
    chown -R consul:consul /opt/consul
    cat >/etc/consul.d/config.json <<EOF
{
    "datacenter": "gce-us-central1",
    "data_dir": "/opt/consul",
    "encrypt": "$${GCE_VAULT_CONSUL_CONSUL_ENCRYPTION_KEY}",
    "bootstrap_expect": $${GCE_VAULT_CONSUL_CONSUL_BOOTSTRAP_EXPECT},
    "server": true
}
EOF
}

__restart_consul() {
    systemctl restart consul.service
}

__write_vault_config() {
    cat >/etc/vault.crt <<EOF
$GCE_VAULT_CONSUL_VAULT_TLS_CERT
EOF
    cat >/etc/vault.key <<EOF
$GCE_VAULT_CONSUL_VAULT_TLS_KEY
EOF
    cat >/etc/vault.hcl <<EOF
backend "consul" {
    address = "127.0.0.1:8500"
}

listener "tcp" {
    address = "0.0.0.0:8200"
    tls_cert_file = "/etc/vault.crt"
    tls_key_file = "/etc/vault.key"
}
EOF
}

__restart_vault() {
    systemctl restart vault.service
}

main "$@"
