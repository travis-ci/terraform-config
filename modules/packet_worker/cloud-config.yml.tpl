#cloud-config
# vim:filetype=yaml

write_files:
- content: '${base64encode(worker_config)}'
  encoding: b64
  path: /etc/default/travis-worker
- content: '${base64encode(cloud_init_env)}'
  encoding: b64
  path: /etc/default/travis-worker-cloud-init
- content: '${base64encode(docker_daemon_json)}'
  encoding: b64
  path: /etc/docker/daemon-direct-lvm.json
- content: '${base64encode(file("${assets}/rsyslog/rsyslog.conf"))}'
  encoding: b64
  path: /etc/rsyslog.conf
- content: '${base64encode(file("${assets}/travis-worker/travis-worker-wrapper"))}'
  encoding: b64
  path: /usr/local/bin/travis-worker-wrapper
  permissions: '0755'
- content: '${base64encode(syslog_address)}'
  encoding: b64
  path: /var/tmp/travis-run.d/syslog-address
- content: '${base64encode(file("${here}/prestart-hook.bash"))}'
  encoding: b64
  path: /var/tmp/travis-run.d/travis-worker-prestart-hook
  permissions: '0750'
- content: '${base64encode(file("${assets}/travis-worker/travis-worker.service"))}'
  encoding: b64
  path: /var/tmp/travis-worker.service
- content: '${base64encode(file("${here}/cloud-init.bash"))}'
  encoding: b64
  permissions: '0755'
  path: /var/tmp/travis-cloud-init.bash
- content: '${base64encode(file("${assets}/tfw.tar.bz2"))}'
  encoding: b64
  permissions: '0644'
  path: /var/tmp/tfw.tar.bz2

runcmd:
- [apt-get, update, -yqq]
- [apt-get, install, -yqq, bzip2]
- [tar, --no-same-permissions, --strip-components=1, -C, /, -xvf, /var/tmp/tfw.tar.bz2]
- [bash, /var/tmp/travis-tfw-bootstrap.bash]
- [bash, /var/tmp/cloud-init.bash]
