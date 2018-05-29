#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
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
- content: '${base64encode(file("${assets}/bits/travis-packet-privnet-setup.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/lib/cloud/scripts/per-boot/00-travis-packet-privnet-setup
- content: '${base64encode(file("${assets}/bits/ensure-tfw.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/lib/cloud/scripts/per-boot/00-ensure-tfw
- content: '${base64encode(file("${assets}/travis-worker/tfw-admin-clean-containers.service"))}'
  encoding: b64
  owner: 'root:root'
  path: '/var/tmp/tfw-admin-clean-containers.service'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/prestart-hook.bash"))}'
  encoding: b64
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(file("${here}/start-hook.bash"))}'
  encoding: b64
  path: /var/tmp/travis-run.d/travis-worker-start-hook
  permissions: '0750'
- content: '${base64encode(file("${here}/stop-hook.bash"))}'
  encoding: b64
  path: /var/tmp/travis-run.d/travis-worker-stop-hook
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.service"))}'
  encoding: b64
  path: /var/tmp/travis-worker.service
- content: '${base64encode(file("${here}/dynamic-config.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-worker-dynamic-config.bash
- content: '${base64encode(worker_config)}'
  encoding: b64
  path: /var/tmp/travis-worker.env.tmpl
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  path: /var/tmp/travis-worker-cloud-init.env.tmpl
