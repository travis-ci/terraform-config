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
- content: '${base64encode(worker_wrapper)}'
  encoding: b64
  owner: 'root:root'
  path: /usr/local/bin/travis-worker-wrapper
- content: '${base64encode(cloud_init_bash)}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-instance/99-travis-worker-cloud-init
  permissions: '0750'
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
- content: '${base64encode(prestart_hook_bash)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(start_hook_bash)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-start-hook
  permissions: '0750'
- content: '${base64encode(stop_hook_bash)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-stop-hook
  permissions: '0750'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
# - content: '${base64encode(unregister_netdevice_crontab)}'
#   encoding: b64
#   owner: 'root:root'
#   path: /etc/cron.d/unregister-netdevice
- content: '${base64encode(check_unregister_netdevice_bash)}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-run.d/check-unregister-netdevice
  permissions: '0750'
- content: '${base64encode(worker_upstart)}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.conf
- content: '${base64encode(worker_service)}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.service
