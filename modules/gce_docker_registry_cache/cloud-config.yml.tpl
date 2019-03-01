#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(docker_config)}'
  encoding: b64
  path: /etc/default/docker
- content: '${base64encode(docker_registry_config)}'
  encoding: b64
  path: /etc/docker/registry/config.yml
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-instance/99-travis-cloud-init
  permissions: '0750'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
