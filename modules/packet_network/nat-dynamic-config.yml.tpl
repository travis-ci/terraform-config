# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(librato_env)}'
  encoding: b64
  path: /etc/default/librato
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(file("${assets}/bits/travis-packet-privnet-setup.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/lib/cloud/scripts/per-boot/00-travis-packet-privnet-setup
- content: '${base64encode(file("${assets}/bits/ensure-tfw.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/lib/cloud/scripts/per-boot/00-ensure-tfw
- content: '${base64encode(duo_config)}'
  encoding: b64
  permissions: '0600'
  path: /var/tmp/duo.conf
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/nat-dynamic-config.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-nat-dynamic-config.bash
