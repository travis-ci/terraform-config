#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(worker_config)}'
  encoding: b64
  #owner: 'travis:travis'
  path: /etc/default/travis-worker
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  #owner: 'travis:travis'
  path: /etc/default/travis-worker-cloud-init
- content: '${base64encode(worker_wrapper)}'
  encoding: b64
  owner: 'root:root'
  path: /usr/local/bin/travis-worker-wrapper
  permissions: '0755'
- content: '${base64encode(prestart_hook_bash)}'
  encoding: b64
  #owner: 'travis:travis'
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(worker_upstart)}'
  encoding: b64
  owner: 'root:root'
  path: /var/tmp/travis-worker.conf
- content: '${base64encode(cloud_init_bash)}'
  encoding: b64
  owner: 'root:root'
  permissions: '0755'
  path: /var/tmp/cloud-init.bash

runcmd:
- [curl, -sL, -o, /usr/local/bin/travis-tfw-combined-env, 'https://raw.githubusercontent.com/travis-ci/packer-templates/master/cookbooks/travis_tfw/files/default/travis-tfw-combined-env']
- [chmod, '0755', /usr/local/bin/travis-tfw-combined-env]
- [ln, -s, /usr/local/bin/travis-tfw-combined-env, /usr/local/bin/travis-combined-env]
- [/var/tmp/cloud-init.bash]
