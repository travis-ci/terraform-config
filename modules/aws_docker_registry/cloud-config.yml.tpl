#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(github_users_env)}'
  encoding: b64
  path: /etc/default/github-users
- content: '${base64encode(cloud_init_bash)}'
  encoding: b64
  path: /var/lib/cloud/scripts/per-instance/99-docker-registry-cloud-init
  permissions: '0750'
- content: '${base64encode(http_secret)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/http-secret
- content: '${base64encode(hostname_tmpl)}'
  encoding: b64
  owner: 'travis:travis'
  path: /var/tmp/travis-run.d/instance-hostname.tmpl
