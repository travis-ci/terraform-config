#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  __log main begin "$LINENO"
  # declared for shellcheck
  local bastion_config
  ${bastion_config}
  __setup_papertrail_rsyslog "$AWS_BASTION_PAPERTRAIL_REMOTE_PORT"
  __write_duo_configs \
    "$AWS_BASTION_DUO_INTEGRATION_KEY" \
    "$AWS_BASTION_DUO_SECRET_KEY" \
    "$AWS_BASTION_DUO_API_HOSTNAME"
  __set_hostname || true
  __log main end "$LINENO"
}

__setup_papertrail_rsyslog() {
  __log setup-papertrail-rsyslog begin "$LINENO"
  local pt_port="$1"

  if [[ ! "$pt_port" ]]; then
    __log setup-papertrail-rsyslog noport "$LINENO"
    return
  fi

  local match='logs.papertrailapp.com:'
  local repl="\*\.\* @logs.papertrailapp.com:$pt_port"

  sed -i "/$match/s/.*/$repl/" '/etc/rsyslog.d/65-papertrail.conf'

  restart rsyslog || start rsyslog
  __log setup-papertrail-rsyslog end "$LINENO"
}

__write_duo_configs() {
  __log write-duo-configs begin "$LINENO"
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
  __log write-duo-configs end "$LINENO"
}

__set_hostname() {
  __log set-hostname begin "$LINENO"
  # declared for shellcheck
  local instance_hostname

  local instance_ipv4

  # shellcheck disable=SC2034
  instance_ipv4="$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')"

  local hosts_line="$instance_ipv4 ${instance_hostname} $${instance%.*}"

  echo "${instance_hostname}" | tee /etc/hostname
  hostname -F /etc/hostname
  echo "$hosts_line" | tee -a /etc/hosts
  __log set-hostname end "$LINENO"
}

__log() {
  echo "time=$(date -u +%Y-%m-%dT%H:%M:%S) " \
    "type=cloud-init step=$1 state=$2 line=$3"
}

main "$@"
