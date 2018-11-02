#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(docker_env)}'
  encoding: b64
  path: /etc/default/docker
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(file("${here}/squignix.env"))}'
  encoding: b64
  path: /etc/default/squignix
- content: '${base64encode(file("${here}/squignix.service"))}'
  encoding: b64
  path: /etc/systemd/system/squignix.service
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(file("${assets}/bits/apt_force_confdef.conf"))}'
  encoding: b64
  path: /etc/apt/apt.conf.d/force_confdef
- content: '${base64encode(file("${here}/squignix-wrapper"))}'
  encoding: b64
  path: /usr/local/bin/squignix-wrapper
  permissions: '0750'
- content: '${base64encode(file("${assets}/bits/ensure-tfw.bash"))}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-boot/00-ensure-tfw
  permissions: '0750'
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-boot/99-cloud-init
  permissions: '0750'
- content: '${base64encode("___INSTANCE_NAME___\n")}'
  encoding: b64
  path: /var/tmp/travis-run.d/instance-hostname.tmpl
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
