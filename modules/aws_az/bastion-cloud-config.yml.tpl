#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(hostname_tmpl)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/instance-hostname.tmpl
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(duo_config)}'
  encoding: b64
  owner: 'sshd:root'
  path: /etc/duo/login_duo.conf
  permissions: '0600'
- content: '${base64encode(duo_config)}'
  encoding: b64
  owner: 'sshd:root'
  path: /etc/duo/pam_duo.conf
  permissions: '0600'
