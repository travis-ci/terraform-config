#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(worker_config)}'
  encoding: b64
  path: /etc/default/travis-worker
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  path: /etc/default/travis-worker-cloud-init
- content: '${base64encode(docker_daemon_json)}'
  encoding: b64
  path: /etc/docker/daemon-direct-lvm.json
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(worker_wrapper)}'
  encoding: b64
  path: /usr/local/bin/travis-worker-wrapper
  permissions: '0755'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(prestart_hook_bash)}'
  encoding: b64
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(worker_upstart)}'
  encoding: b64
  path: /var/tmp/travis-worker.conf
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-cloud-init.bash
- content: '${base64encode(file("${assets}/tfw/bootstrap.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-tfw-bootstrap.bash

runcmd:
- [/var/tmp/tfw-bootstrap.bash]
- [/var/tmp/cloud-init.bash]
