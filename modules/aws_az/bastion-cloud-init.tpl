#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  # declared for shellcheck
  local bastion_config
  ${bastion_config}
  __setup_papertrail_rsyslog "$AWS_BASTION_PAPERTRAIL_REMOTE_PORT"
  __write_duo_configs \
    "$AWS_BASTION_DUO_INTEGRATION_KEY" \
    "$AWS_BASTION_DUO_SECRET_KEY" \
    "$AWS_BASTION_DUO_API_HOSTNAME"
  __set_hostname || true
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

__set_hostname() {
  # declared for shellcheck
  local env

  local instance_id
  local instance_ipv4

  # shellcheck disable=SC2034
  instance_id="$(curl -s 'http://169.254.169.254/latest/meta-data/instance-id')"
  instance_ipv4="$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')"

  local instance_hostname="bastion-$${instance_id#i-}.${env}.travis-ci.com"
  local hosts_line="$instance_ipv4 $instance_hostname $${instance%.*}"

  echo "$instance_hostname" | tee /etc/hostname
  hostname -F /etc/hostname
  echo "$hosts_line" | tee -a /etc/hosts
}

main "$@"
