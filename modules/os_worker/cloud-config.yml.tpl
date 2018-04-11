#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(worker_config)}'
  encoding: b64
  path: /etc/default/travis-worker
- content: '${base64encode(file("${here}/cloud-init-${provider}.bash"))}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-instance/99-travis-worker-cloud-init
  permissions: '0750'
- content: '${base64encode(file("${here}/travis-worker-${provider}.service"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.service
