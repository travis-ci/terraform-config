#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit

main() {
  # shellcheck source=/dev/null
  source /etc/default/nat
  __write_duo_configs \
    "$GCE_NAT_DUO_INTEGRATION_KEY" \
    "$GCE_NAT_DUO_SECRET_KEY" \
    "$GCE_NAT_DUO_API_HOSTNAME"
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
