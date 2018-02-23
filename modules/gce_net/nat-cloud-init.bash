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
  __setup_nat_conntracker_fail2ban
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
  if [[ ! "${1}" || ! "${2}" ]]; then
    return
  fi

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
  local pub_iface
  pub_iface="$(__find_public_interface)"

  sysctl -w net.ipv4.ip_forward=1

  iptables -t nat -S POSTROUTING | if ! grep -q MASQUERADE; then
    iptables -t nat -A POSTROUTING -o "${pub_iface}" -j MASQUERADE
  fi

  iptables -S FORWARD | if ! grep -q conntrack; then
    iptables -A FORWARD -o "${pub_iface}" \
      -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  fi
}

__find_public_interface() {
  local iface=ens4
  iface="$(ip -o addr show | grep -vE 'inet (172|127)\.' | grep -v inet6 |
    awk '{ print $2 }' | grep -v '^lo$' | head -n 1)"
  echo "${iface:-ens4}"
}


__setup_nat_conntracker_fail2ban() {
  local ncc="${VARTMP}/nat-conntracker-confs"

	if [[ ! -d "${ETCDIR}/fail2ban" ]]; then
    return
  fi

  if [[ ! -d "${ncc}" ]]; then
    return
  fi

  if ! systemctl is-enabled nat-conntracker.service &>/dev/null; then
    return
  fi

  if ! systemctl is-enabled fail2ban.service &>/dev/null; then
    return
  fi

  cp -v "${ncc}/fail2ban-action-iptables-blocktype.local" \
        "${ETCDIR}/fail2ban/action.d/iptables-blocktype.local"

  cp -v "${ncc}/fail2ban-filter-nat-conntracker.conf" \
        "${ETCDIR}/fail2ban/filter.d/nat-conntracker.conf"

  cp -v "${ncc}/fail2ban-jail-nat-conntracker.conf" \
        "${ETCDIR}/fail2ban/jail.d/nat-conntracker.conf"

  systemctl restart fail2ban
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
