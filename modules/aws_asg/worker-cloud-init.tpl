#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  local instance_id
  instance_id="$(curl -s 'http://169.254.169.254/latest/meta-data/instance-id')"

  __write_docker_registry_info
  __write_travis_worker_configs "$${instance_id}"
  __write_travis_worker_hooks "$${instance_id}"
  __setup_papertrail_rsyslog
  __fix_perms
  __restart_worker
  __set_hostname "$${instance_id}" || true
}

__write_docker_registry_info() {
  local az
  # shellcheck disable=SC2034
  az="$(curl -s 'http://169.254.169.254/latest/meta-data/placement/availability-zone')"
  "__write_docker_registry_$${az##*-}_host"
  "__write_docker_registry_$${az##*-}_auth"
}

__write_docker_registry_1b_host() {
  # declared for shellcheck
  local docker_registry_1b_hostname
  local docker_registry_1b_private_ip

  __write_etc_hosts_record \
    "${docker_registry_1b_private_ip} ${docker_registry_1b_hostname}"
  echo "${docker_registry_1b_hostname}" \
    | tee /var/tmp/travis-run.d/registry-hostname
}

__write_docker_registry_1e_host() {
  # declared for shellcheck
  local docker_registry_1e_hostname
  local docker_registry_1e_private_ip

  __write_etc_hosts_record \
    "${docker_registry_1e_private_ip} ${docker_registry_1e_hostname}"
  echo "${docker_registry_1e_hostname}" \
    | tee /var/tmp/travis-run.d/registry-hostname
}

__write_docker_registry_1b_auth() {
  # declared for shellcheck
  local docker_registry_1b_worker_auth

  echo "${docker_registry_1b_worker_auth}" \
    | tee /var/tmp/travis-run.d/registry-auth
}

__write_docker_registry_1e_auth() {
  # declared for shellcheck
  local docker_registry_1e_worker_auth

  echo "${docker_registry_1e_worker_auth}" \
    | tee /var/tmp/travis-run.d/registry-auth
}

__write_etc_hosts_record() {
  local hosts_line="$1"

  if grep -qE "^$hosts_line\$" /etc/hosts; then
    return
  fi

  echo "$hosts_line" | tee -a /etc/hosts
}

__write_travis_worker_configs() {
  # declared for shellcheck
  local cyclist_url
  local worker_cache_access_key
  local worker_cache_bucket
  local worker_cache_secret_key
  local worker_config
  local worker_docker_self_image

  local instance_id="$${1}"

  cat >/etc/default/travis-worker <<EOF
${worker_config}
EOF
  cat >/etc/default/travis-worker-cloud-init <<EOF
export TRAVIS_WORKER_BUILD_CACHE_S3_ACCESS_KEY_ID=${worker_cache_access_key}
export TRAVIS_WORKER_BUILD_CACHE_S3_BUCKET=${worker_cache_bucket}
export TRAVIS_WORKER_BUILD_CACHE_S3_SECRET_ACCESS_KEY=${worker_cache_secret_key}
export TRAVIS_WORKER_HEARTBEAT_URL=${cyclist_url}/heartbeats/$${instance_id}
export TRAVIS_WORKER_HEARTBEAT_URL_AUTH_TOKEN=file:///var/tmp/travis-run.d/instance-token
export TRAVIS_WORKER_PRESTART_HOOK=/var/tmp/travis-run.d/travis-worker-prestart-hook
export TRAVIS_WORKER_SELF_IMAGE=${worker_docker_self_image}
export TRAVIS_WORKER_START_HOOK=/var/tmp/travis-run.d/travis-worker-start-hook
export TRAVIS_WORKER_STOP_HOOK=/var/tmp/travis-run.d/travis-worker-stop-hook
EOF
}

__write_travis_worker_hooks() {
  # declared for shellcheck
  local cyclist_auth_token
  local cyclist_url
  local worker_docker_image_android
  local worker_docker_image_default
  local worker_docker_image_erlang
  local worker_docker_image_go
  local worker_docker_image_haskell
  local worker_docker_image_jvm
  local worker_docker_image_node_js
  local worker_docker_image_perl
  local worker_docker_image_php
  local worker_docker_image_python
  local worker_docker_image_ruby

  local instance_id="$${1}"

  mkdir -p /var/tmp/travis-run.d
  cat >/var/tmp/travis-run.d/travis-worker-start-hook <<EOF
#!/bin/bash
[[ -f /var/tmp/travis-run.d/instance-token ]] || {
  echo "Missing instance token" >&2
  exit 1
}
exec curl \\
  -f \\
  -X POST \\
  -H "Authorization: token \$(cat /var/tmp/travis-run.d/instance-token)" \\
  "${cyclist_url}/launches/$${instance_id}"
EOF
  chmod +x /var/tmp/travis-run.d/travis-worker-start-hook
  cat >/var/tmp/travis-run.d/travis-worker-stop-hook <<EOF
#!/bin/bash
[[ -f /var/tmp/travis-run.d/instance-token ]] || {
  echo "Missing instance token" >&2
  exit 1
}
exec curl \\
  -f \\
  -X POST \\
  -H "Authorization: token \$(cat /var/tmp/travis-run.d/instance-token)" \\
  "${cyclist_url}/terminations/$${instance_id}"
EOF
  chmod +x /var/tmp/travis-run.d/travis-worker-stop-hook
  cat >/var/tmp/travis-run.d/travis-worker-prestart-hook <<EOF
#!/bin/bash
set -o errexit

main() {
  if [[ ! -f /var/tmp/travis-run.d/instance-token ]]; then
    curl \\
      -f \\
      -s \\
      -o /var/tmp/travis-run.d/instance-token \\
      -H 'Accept: text/plain' \\
      -H 'Authorization: token ${cyclist_auth_token}' \\
      "${cyclist_url}/tokens/$${instance_id}"
  fi

  set -o xtrace

  local i=0
  while ! docker version ; do
    if [[ \$i -gt 600 ]]; then
      exit 86
    fi
    sleep 10
    let i+=10
  done

  local docker_registry_hostname
  docker_registry_hostname="\$(cat /var/tmp/travis-run.d/registry-hostname)"

  docker login \\
    -u travis-worker \\
    -p <(cat /var/tmp/travis-run.d/registry-auth) \\
    "\$docker_registry_hostname"

  __docker_double_pull_tag "${worker_docker_image_android}" travis:android
  __docker_double_pull_tag "${worker_docker_image_default}" travis:default
  __docker_double_pull_tag "${worker_docker_image_erlang}" travis:erlang
  __docker_double_pull_tag "${worker_docker_image_go}" travis:go
  __docker_double_pull_tag "${worker_docker_image_haskell}" travis:haskell
  __docker_double_pull_tag "${worker_docker_image_jvm}" travis:jvm
  __docker_double_pull_tag "${worker_docker_image_node_js}" travis:node-js
  __docker_double_pull_tag "${worker_docker_image_perl}" travis:perl
  __docker_double_pull_tag "${worker_docker_image_php}" travis:php
  __docker_double_pull_tag "${worker_docker_image_python}" travis:python
  __docker_double_pull_tag "${worker_docker_image_ruby}" travis:ruby

  docker logout "\$docker_registry_hostname"
}

__docker_double_pull_tag() {
  local image="\$1"
  local tag="\$2"
  local local_registry_image_name
  local_registry_image_name="\$(__local_registry_image_name "\$image")"

  if docker pull "\$local_registry_image_name"; then
    docker tag "\$local_registry_image_name" "\$tag"
    return
  fi

  docker pull "\$image"
  docker tag "\$image" "\$tag"
  docker tag "\$image" "\$local_registry_image_name"
}

__local_registry_image_name() {
  local registry_hostname="\$1"
  local image="\$2"
  echo "\$registry_hostname/\$(basename "\$image")"
}

main "\$@"
EOF
}

__setup_papertrail_rsyslog() {
  # declared for shellcheck
  local syslog_address
  local syslog_host

  if [[ ! "${syslog_address}" ]]; then
    return
  fi

  if [ ! -f '/etc/rsyslog.d/65-papertrail.conf' ]; then
    return
  fi

  local match="${syslog_host}:"
  local repl="\*\.\* @${syslog_address}"

  sed -i "/$match/s/.*/$repl/" '/etc/rsyslog.d/65-papertrail.conf'

  restart rsyslog || start rsyslog
}

__fix_perms() {
  chown -R travis:travis /etc/default/travis-worker* /var/tmp/*
  chmod 0640 /etc/default/travis-worker*
  chmod 0750 /var/tmp/travis-run.d/travis-worker*hook
}

__restart_worker() {
  stop travis-worker || true
  start travis-worker || true
}

__set_hostname() {
  # declared for shellcheck
  local index
  local env
  local site
  local queue

  # shellcheck disable=SC2034
  local instance_id="$${1}"
  local instance_ipv4
  instance_ipv4="$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')"

  local instance_hostname="worker-${queue}-$${instance_id#i-}.${env}-${index}.travis-ci.${site}"
  local hosts_line="$instance_ipv4 $instance_hostname $${instance%.*}"

  echo "$instance_hostname" | tee /etc/hostname
  hostname -F /etc/hostname
  __write_etc_hosts_record "$hosts_line"
}

main "$@"
