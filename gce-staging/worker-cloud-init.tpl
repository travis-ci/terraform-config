#!/usr/bin/env bash

set -o errexit

main() {
  __write_gce_json
  __write_travis_worker_configs
  __setup_papertrail_rsyslog
  __fix_perms
  __restart_worker
  __write_chef_node_json
}

__restart_worker() {
  stop travis-worker || true
  start travis-worker || true
}

__write_gce_json() {
  cat > /var/tmp/gce.json <<EOF
${account_json}
EOF
}

__write_travis_worker_configs() {
  cat > /etc/default/travis-worker <<EOF
${worker_config}
EOF
}

__setup_papertrail_rsyslog() {
  source /etc/default/travis-worker
  local pt_port="$TRAVIS_WORKER_PAPERTRAIL_REMOTE_PORT"

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

__write_chef_node_json() {
  mkdir -p /etc/chef

  cat > /etc/chef/node.json <<EOF
${chef_json}
EOF
}

main "$@"
