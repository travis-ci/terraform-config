#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: ''
  encoding: b64
  owner: 'travis:travis'
  path: /etc/default/travis-worker
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  owner: 'travis:travis'
  path: /etc/default/travis-worker-cloud-init
- content: '${base64encode(docker_daemon_json)}'
  encoding: b64
  owner: 'root:root'
  path: /etc/docker/daemon-direct-lvm.json
- content: '${base64encode(file("${assets}/travis-worker/travis-worker-wrapper"))}'
  encoding: b64
  owner: 'root:root'
  path: /usr/local/bin/travis-worker-wrapper
  permissions: '0755'
- content: '${base64encode(file("${assets}/bits/travis-combined-env"))}'
  encoding: b64
  owner: 'root:root'
  path: /usr/local/bin/travis-combined-env
  permissions: '0755'
- content: '${base64encode(file("${here}/prestart-hook.bash"))}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.conf"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.conf
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.service"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.service
