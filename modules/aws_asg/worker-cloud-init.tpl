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
  cat > /etc/default/travis-worker-local <<EOF
export TRAVIS_WORKER_START_HOOK=/var/tmp/travis-run.d/travis-worker-start-hook
export TRAVIS_WORKER_STOP_HOOK=/var/tmp/travis-run.d/travis-worker-stop-hook
export TRAVIS_WORKER_HEARTBEAT_URL=${cyclist_url}/heartbeats/$${instance_id}
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
  cat > /var/tmp/travis-run.d/travis-worker-stop-hook <<EOF
#!/usr/bin/env bash
exec curl \\
  -s \\
  -X POST \\
  -H 'Authorization: token ${cyclist_auth_token}' \\
  "${cyclist_url}/terminations/$${instance_id}"
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
  chmod 0640 /etc/default/travis-worker* /var/tmp/gce*
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
