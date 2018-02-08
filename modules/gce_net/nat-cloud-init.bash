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

  __write_librato_config \
    "${GCE_NAT_LIBRATO_EMAIL}" \
    "${GCE_NAT_LIBRATO_TOKEN}"

  __setup_nat_forwarding
  __setup_nat_health_check
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

__write_librato_config() {
  mkdir -p "${ETCDIR}/collectd/collectd.conf.d"

  local hostname_tmpl="${VARTMP}/travis-run.d/instance-hostname.tmpl"
  local hostname_setting
  if [[ -f "${hostname_tmpl}" ]]; then
    local region_zone hostname_rendered
    region_zone="$(__fetch_region_zone)"
    hostname_rendered="$(
      sed "s/___REGION_ZONE___/${region_zone}/g" <"${hostname_tmpl}"
    )"
    hostname_setting="Hostname ${hostname_rendered}"
  fi

  cat >"${ETCDIR}/collectd/collectd.conf.d/librato.conf" <<EOF
# Written by cloud-init $(date -u) :heart:
${hostname_setting}
LoadPlugin write_http

<Plugin "write_http">
  <Node "Librato">
    URL "https://collectd.librato.com/v1/measurements"
    User "${1}"
    Password "${2}"
    Format "JSON"
  </Node>
</Plugin>
EOF
}

__setup_nat_forwarding() {
  sysctl -w net.ipv4.ip_forward=1
  iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
}

__setup_nat_health_check() {
  local service_src="${VARTMP}/travis-nat-health-check.service"
  local service_dest="${ETCDIR}/systemd/system/travis-nat-health-check.service"

  if [[ -f "${service_src}" && -d "$(dirname "${service_dest}")" ]]; then
    cp -v "${service_src}" "${service_dest}"

    systemctl enable travis-nat-health-check || true
    systemctl start travis-nat-health-check || true
  fi
}

__fetch_region_zone() {
  curl -s -H 'Metadata-Flavor: Google' \
    http://metadata.google.internal/computeMetadata/v1/instance/zone |
    awk -F/ '{ print $NF }'
}

main "${@}"
