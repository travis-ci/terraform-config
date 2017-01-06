#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  # declared for shellcheck
  local hashistack_server_config
  ${hashistack_server_config}
  export GCE_HASHISTACK_SERVER_CONSUL_ENCRYPTION_KEY GCE_HASHISTACK_SERVER_CONSUL_BOOTSTRAP_EXPECT GCE_HASHISTACK_SERVER_CONSUL_TLS_KEY GCE_HASHISTACK_SERVER_CONSUL_TLS_CERT GCE_HASHISTACK_SERVER_VAULT_TLS_CERT GCE_HASHISTACK_SERVER_VAULT_TLS_KEY GCE_HASHISTACK_SERVER_NOMAD_ENCRYPTION_KEY GCE_HASHISTACK_SERVER_NOMAD_BOOTSTRAP_EXPECT GCE_HASHISTACK_SERVER_NOMAD_TLS_CERT GCE_HASHISTACK_SERVER_NOMAD_TLS_KEY GCE_HASHISTACK_SERVER_TRAVIS_CA_CERT
  __install_ca_cert
  __write_consul_config
  __restart_consul
  __write_vault_config
  __restart_vault
  __write_nomad_config
  __restart_nomad
}

__install_ca_cert() {
  cat >/etc/travis-ca.crt <<EOF
$${GCE_HASHISTACK_SERVER_TRAVIS_CA_CERT}
EOF
}

__write_consul_config() {
  mkdir /opt/consul
  chmod 0700 /opt/consul
  chown -R consul:consul /opt/consul
  touch /etc/consul.{crt,key}
  chmod 0600 /etc/consul.{key,crt}
  chown consul:consul /etc/consul.{key,crt}
  cat >/etc/consul.crt <<EOF
$${GCE_HASHISTACK_SERVER_CONSUL_TLS_CERT}
EOF
  cat >/etc/consul.key <<EOF
$${GCE_HASHISTACK_SERVER_CONSUL_TLS_KEY}
EOF

  cat >/etc/consul.d/config.json <<EOF
{
    "datacenter": "gce-us-central1",
    "data_dir": "/opt/consul",
    "encrypt": "$${GCE_HASHISTACK_SERVER_CONSUL_ENCRYPTION_KEY}",
    "bootstrap_expect": $${GCE_HASHISTACK_SERVER_CONSUL_BOOTSTRAP_EXPECT},
    "server": true,
    "cert_file": "/etc/consul.crt",
    "key_file": "/etc/consul.key",
    "ca_file": /etc/travis-ca.crt",
    "verify_server_hostname:" true,
    "verify_incoming": true,
    "verify_outgoing": true
}
EOF
}

__restart_consul() {
  systemctl restart consul.service
}

__write_vault_config() {
  cat >/etc/vault.crt <<EOF
$${GCE_HASHISTACK_SERVER_VAULT_TLS_CERT}
EOF
  cat >/etc/vault.key <<EOF
$${GCE_HASHISTACK_SERVER_VAULT_TLS_KEY}
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

__write_nomad_config() {
  mkdir /opt/nomad
  chmod 0700 /opt/nomad
  chown -R nomad:nomad /opt/nomad
  touch /etc/nomad.{crt,key}
  chmod 0600 /etc/nomad.{key,crt}
  chown nomad:nomad /etc/nomad.{key,crt}
  cat >/etc/nomad.crt <<EOF
$${GCE_HASHISTACK_SERVER_NOMAD_TLS_CERT}
EOF
  cat >/etc/nomad.key <<EOF
$${GCE_HASHISTACK_SERVER_NOMAD_TLS_KEY}
EOF
  cat >/etc/nomad.d/config.json <<EOF
{
  "region": "us",
  "datacenter": "gce-us-central1",
  "data_dir": "/opt/nomad",
  "server": {
    "enabled": true,
    "bootstrap_expect": $${GCE_HASHISTACK_SERVER_NOMAD_BOOTSTRAP_EXPECT},
    "encrypt": "$${GCE_HASHISTACK_SERVER_NOMAD_ENCRYPTION_KEY}",
  },
  "tls": {
    "http": true,
    "rpc": true,
    "ca_file": "/etc/travis-ca.crt",
    "cert_file": "/etc/nomad.crt",
    "key_file": "/etc/nomad.key",
    "verify_server_hostname": true
  }
}
EOF
}

__restart_nomad() {
  systemctl restart nomad.service
}

main "$@"
