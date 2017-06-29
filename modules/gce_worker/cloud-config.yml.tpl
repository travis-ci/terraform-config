#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(worker_config)}'
  encoding: b64
  owner: 'travis:travis'
  path: /etc/default/travis-worker
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  owner: 'travis:travis'
  path: /etc/default/travis-worker-cloud-init
- content: '${base64encode(docker_env)}'
  encoding: b64
  owner: 'root:root'
  path: /etc/default/docker
- content: '${base64encode(worker_wrapper)}'
  encoding: b64
  owner: 'root:root'
  path: /usr/local/bin/travis-worker-wrapper
  permissions: '0755'
- content: '${base64encode(gce_account_json)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/gce.json
- content: '${base64encode(cloud_init_bash)}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-instance/99-travis-worker-cloud-init
  permissions: '0750'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(worker_upstart)}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.conf
- content: '${base64encode(worker_service)}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.service
