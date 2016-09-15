#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  local instance_id
  instance_id="$(curl -s 'http://169.254.169.254/latest/meta-data/instance-id')"

  __write_travis_worker_configs "$${instance_id}"
  __write_travis_worker_hooks "$${instance_id}"

  source /etc/default/travis-worker

  __setup_papertrail_rsyslog "$${TRAVIS_WORKER_PAPERTRAIL_REMOTE_PORT}"
  __fix_perms
  __restart_worker
  __set_hostname "$${instance_id}" || true
}

__restart_worker() {
  stop travis-worker || true
  start travis-worker || true
}

__write_travis_worker_configs() {
  local instance_id="$${1}"

  cat > /etc/default/travis-worker <<EOF
${worker_config}
EOF
  cat > /etc/default/travis-worker-cloud-init <<EOF
export TRAVIS_WORKER_HEARTBEAT_URL=${cyclist_url}/heartbeats/$${instance_id}
export TRAVIS_WORKER_PRESTART_HOOK=/var/tmp/travis-run.d/travis-worker-prestart-hook
export TRAVIS_WORKER_START_HOOK=/var/tmp/travis-run.d/travis-worker-start-hook
export TRAVIS_WORKER_STOP_HOOK=/var/tmp/travis-run.d/travis-worker-stop-hook
EOF
}

__write_travis_worker_hooks() {
  local instance_id="$${1}"

  mkdir -p /var/tmp/travis-run.d
  cat > /var/tmp/travis-run.d/travis-worker-start-hook <<EOF
#!/usr/bin/env bash
exec curl \\
  -s \\
  -X POST \\
  -H 'Authorization: token ${cyclist_auth_token}' \\
  "${cyclist_url}/launches/$${instance_id}"
EOF
  chmod +x /var/tmp/travis-run.d/travis-worker-start-hook
  cat > /var/tmp/travis-run.d/travis-worker-stop-hook <<EOF
#!/usr/bin/env bash
exec curl \\
  -s \\
  -X POST \\
  -H 'Authorization: token ${cyclist_auth_token}' \\
  "${cyclist_url}/terminations/$${instance_id}"
EOF
  chmod +x /var/tmp/travis-run.d/travis-worker-stop-hook
  cat > /var/tmp/travis-run.d/travis-worker-prestart-hook <<EOF
#!/usr/bin/env bash
set -o errexit

main() {
  set -o xtrace

  local i=0
  while ! docker version ; do
    if [ $${i} -gt 600 ]; then
      exit 86
    fi
    sleep 10
    let i+=10
  done

  docker pull "${worker_docker_image_android}"
  docker tag "${worker_docker_image_android}" travis:android

  docker pull "${worker_docker_image_default}"
  docker tag "${worker_docker_image_default}" travis:default

  docker pull "${worker_docker_image_erlang}"
  docker tag "${worker_docker_image_erlang}" travis:erlang

  docker pull "${worker_docker_image_go}"
  docker tag "${worker_docker_image_go}" travis:go

  docker pull "${worker_docker_image_haskell}"
  docker tag "${worker_docker_image_haskell}" travis:haskell

  docker pull "${worker_docker_image_jvm}"
  docker tag "${worker_docker_image_jvm}" travis:jvm

  docker pull "${worker_docker_image_node_js}"
  docker tag "${worker_docker_image_node_js}" travis:node-js

  docker pull "${worker_docker_image_perl}"
  docker tag "${worker_docker_image_perl}" travis:perl

  docker pull "${worker_docker_image_php}"
  docker tag "${worker_docker_image_php}" travis:php

  docker pull "${worker_docker_image_python}"
  docker tag "${worker_docker_image_python}" travis:python

  docker pull "${worker_docker_image_ruby}"
  docker tag "${worker_docker_image_ruby}" travis:ruby
}

main "\$@"
EOF
}

__setup_papertrail_rsyslog() {
  local pt_port="$1"

  if [[ ! "$pt_port" ]] ; then
    return
  fi

  local match='logs.papertrailapp.com:'
  local repl="\*\.\* @logs.papertrailapp.com:$pt_port"

  sed -i "/$match/s/.*/$repl/" '/etc/rsyslog.d/65-papertrail.conf'

  restart rsyslog || start rsyslog
}

__fix_perms() {
  chown -R travis:travis /etc/default/travis-worker* /var/tmp/*
  chmod 0640 /etc/default/travis-worker*
  chmod 0750 /var/tmp/travis-run.d/travis-worker*hook
}

__set_hostname() {
  local instance_id="$${1}"
  local instance_ipv4

  instance_ipv4="$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')"

  local instance_hostname="worker-docker-$${instance_id#i-}-${index}.${env}.travis-ci.${site}"
  local hosts_line="$${instance_ipv4} $${instance_hostname} $${instance%.*}"

  echo "$${instance_hostname}" | tee /etc/hostname
  hostname -F /etc/hostname
  echo "$${hosts_line}" | tee -a /etc/hosts
}

main "$@"
