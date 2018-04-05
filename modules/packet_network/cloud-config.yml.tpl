#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(librato_env)}'
  encoding: b64
  path: /etc/default/librato
- content: '${base64encode(instance_env)}'
  encoding: b64
  path: /etc/default/travis-instance
- content: '${base64encode(network_env)}'
  encoding: b64
  path: /etc/default/travis-network
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(duo_config)}'
  encoding: b64
  permissions: '0600'
  path: /var/tmp/duo.conf
- content: '${base64encode(terraform_pubkey)}'
  encoding: b64
  permissions: '0644'
  path: /var/tmp/terraform_rsa.pub
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-cloud-init.bash
- content: '${base64encode(file("${assets}/tfw.tar.bz2"))}'
  encoding: b64
  permissions: '0644'
  path: /var/tmp/tfw.tar.bz2

runcmd:
- [bash, /var/tmp/travis-cloud-init.bash]
