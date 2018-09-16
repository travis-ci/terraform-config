#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(docker_config)}'
  encoding: b64
  path: /etc/default/docker
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-instance/99-bastion-cloud-init
  permissions: '0750'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/daemon-direct-lvm.json"))}'
  encoding: b64
  path: /var/tmp/daemon-direct-lvm.json
- content: '${base64encode(docker_ca_pem)}'
  encoding: b64
  path: /var/tmp/docker-certs/ca.pem
- content: '${base64encode(docker_server_cert_pem)}'
  encoding: b64
  path: /var/tmp/docker-certs/server-cert.pem
- content: '${base64encode(docker_server_key_pem)}'
  encoding: b64
  path: /var/tmp/docker-certs/server-key.pem
