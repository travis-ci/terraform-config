#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(duo_config)}'
  encoding: b64
  permissions: '0600'
  path: /var/tmp/duo.conf
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/syslog-address
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-cloud-init.bash
- content: '${base64encode(file("${assets}/travis-tfw-bootstrap.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-tfw-bootstrap.bash

runcmd:
- [/var/tmp/tfw-bootstrap.bash]
- [/var/tmp/cloud-init.bash]
