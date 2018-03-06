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
- content: '${base64encode(cyclist_url)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/cyclist-url
- content: '${base64encode(hostname_tmpl)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/instance-hostname.tmpl
- content: '${base64encode(registry_hostname)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/registry-hostname
- content: '${base64encode(file("${here}/prestart-hook.bash"))}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(file("${here}/start-hook.bash"))}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-start-hook
  permissions: '0750'
- content: '${base64encode(file("${here}/stop-hook.bash"))}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-stop-hook
  permissions: '0750'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/check-unregister-netdevice.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/check-unregister-netdevice
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.conf"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.conf
- content: '${base64encode(file("${here}/check-docker-health.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/check-docker-health
  permissions: '0750'
- content: '${base64encode(file("${here}/check-docker-health-crontab"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/cron.d/check-docker-health-crontab
  permissions: '0644'
- content: '${base64encode(file("${here}/kill-old-containers.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/kill-old-containers
  permissions: '0750'
- content: '${base64encode(file("${here}/kill-old-containers-crontab"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/cron.d/kill-old-containers-crontab
  permissions: '0644'
- content: '${base64encode(file("${here}/high-cpu-check.bash"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/high-cpu-check
  permissions: '0750'
- content: '${base64encode(file("${here}/high-cpu-check-crontab"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/cron.d/high-cpu-check-crontab
  permissions: '0644'
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.service"))}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.service
- content: '${base64encode(file("${assets}/travis-worker/rsyslog-watch-upstart.conf"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/rsyslog.d/60-travis-worker.conf
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  owner: 'root:root'
  path: /etc/rsyslog.conf
