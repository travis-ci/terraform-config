#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(worker_config)}'
  encoding: b64
  path: /etc/default/travis-worker
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  path: /etc/default/travis-worker-cloud-init
- content: '${base64encode(instance_env)}'
  encoding: b64
  path: /etc/default/travis-instance
- content: '${base64encode(network_env)}'
  encoding: b64
  path: /etc/default/travis-network
- content: '${base64encode(docker_daemon_json)}'
  encoding: b64
  path: /etc/docker/daemon-direct-lvm.json
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(file("${assets}/travis-worker/travis-worker-wrapper"))}'
  encoding: b64
  path: /usr/local/bin/travis-worker-wrapper
  permissions: '0755'
- content: '${base64encode(file("${assets}/travis-worker/check-unregister-netdevice.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/check-unregister-netdevice
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/clean-up-containers.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/clean-up-containers
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/clean-up-containers.crontab"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/cron.d/travis-worker-clean-up-containers
  permissions: '0644'
- content: '${base64encode(file("${assets}/travis-worker/high-cpu-check.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/high-cpu-check
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/high-cpu-check.crontab"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/cron.d/travis-worker-high-cpu-check
  permissions: '0644'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/prestart-hook.bash"))}'
  encoding: b64
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.service"))}'
  encoding: b64
  path: /var/tmp/travis-worker.service
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-cloud-init.bash
- content: '${base64encode(file("${assets}/bits/travis-packet-privnet-setup.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/lib/cloud/scripts/per-boot/00-travis-packet-privnet-setup
