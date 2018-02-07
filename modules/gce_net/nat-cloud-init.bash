#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit

main() {
  : "${VARTMP:=/var/tmp}"
  : "${ETCDIR:=/etc}"

  # shellcheck source=/dev/null
  source "${ETCDIR}/default/nat"
  __write_duo_configs \
    "${GCE_NAT_DUO_INTEGRATION_KEY}" \
    "${GCE_NAT_DUO_SECRET_KEY}" \
    "${GCE_NAT_DUO_API_HOSTNAME}"

  local service_src="${VARTMP}/travis-nat-health-check.service"
  local service_dest="${ETCDIR}/systemd/system/travis-nat-health-check.service"

  if [[ -f "${service_src}" && -d "$(dirname "${service_dest}")" ]]; then
    cp -v "${service_src}" "${service_dest}"

    systemctl enable travis-nat-health-check || true
    systemctl start travis-nat-health-check || true
  fi
}

__write_duo_configs() {
  mkdir -p "${ETCDIR}/duo"
  for conf in "${ETCDIR}/duo/login_duo.conf" "${ETCDIR}/duo/pam_duo.conf"; do
    cat >"${conf}" <<EOF
# Written by cloud-init $(date -u) :heart:
[duo]
ikey = ${1}
skey = ${2}
host = ${3}
failmode = secure
EOF
  done
}

main "${@}"
