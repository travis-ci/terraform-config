#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(docker_env)}'
  encoding: b64
  owner: 'root:root'
  path: /etc/default/docker
- content: '${base64encode(gesund_config)}'
  encoding: b64
  path: /etc/default/gesund
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(nat_config)}'
  encoding: b64
  path: /etc/default/nat
- content: '${base64encode(nat_conntracker_config)}'
  encoding: b64
  path: /etc/default/nat-conntracker
- content: '${base64encode(cloud_init_bash)}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-boot/99-nat-cloud-init
  permissions: '0750'
- content: '${filebase64("${assets}/nat.tar.bz2")}'
  encoding: b64
  path: /var/tmp/nat.tar.bz2
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address

runcmd:
- [/var/lib/cloud/scripts/per-boot/99-nat-cloud-init]
