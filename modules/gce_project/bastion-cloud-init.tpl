#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  # declared for shellcheck
  local bastion_config
  local github_users

  ${bastion_config}
  __setup_papertrail_rsyslog "$GCE_BASTION_PAPERTRAIL_REMOTE_PORT"
  __write_github_users "${github_users}"
  __write_duo_configs \
    "$GCE_BASTION_DUO_INTEGRATION_KEY" \
    "$GCE_BASTION_DUO_SECRET_KEY" \
    "$GCE_BASTION_DUO_API_HOSTNAME"
}

__setup_papertrail_rsyslog() {
  local pt_port="$1"

  if [[ ! "$pt_port" ]]; then
    return
  fi

  local match='logs.papertrailapp.com:'
  local repl="\*\.\* @logs.papertrailapp.com:$pt_port"

  sed -i "/$match/s/.*/$repl/" '/etc/rsyslog.d/65-papertrail.conf'

  restart rsyslog || start rsyslog
}

__write_github_users() {
  local github_users="$1"

  cat >/etc/default/github-users <<EOF
export GITHUB_USERS="${github_users}"
EOF
}

__write_duo_configs() {
  for conf in /etc/duo/login_duo.conf /etc/duo/pam_duo.conf; do
    cat >"$conf" <<EOF
# Written by cloud-init $(date -u) :heart:
[duo]
ikey = $1
skey = $2
host = $3
failmode = secure
EOF
  done
}

main "$@"
