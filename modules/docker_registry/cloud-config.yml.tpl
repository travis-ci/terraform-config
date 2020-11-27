#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(REGISTRY_HTTP_TLS_CERTIFICATE)}'
  encoding: b64
  path: /etc/ssl/docker/tls.crt
- content: '${base64encode(REGISTRY_HTTP_TLS_KEY)}'
  encoding: b64
  path: /etc/ssl/docker/tls.key
- content: '${base64encode(registry_env)}'
  encoding: b64
  path: /etc/docker/registry/env
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-boot/99-cloud-init
  permissions: '0750'
- content: '${base64encode(docker_registry_config)}'
  encoding: b64
  path: /etc/docker/registry/config.yml
- content: '${base64encode("___INSTANCE_NAME___\n")}'
  encoding: b64
  path: /var/tmp/travis-run.d/instance-hostname.tmpl
