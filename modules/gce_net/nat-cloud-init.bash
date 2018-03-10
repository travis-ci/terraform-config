#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  : "${USRLOCAL:=/usr/local}"
  : "${VARTMP:=/var/tmp}"
  : "${ETCDIR:=/etc}"

  export DEBIAN_FRONTEND=noninteractive

  # shellcheck source=/dev/null
  source "${ETCDIR}/default/nat"
  __write_duo_configs \
    "${GCE_NAT_DUO_INTEGRATION_KEY}" \
    "${GCE_NAT_DUO_SECRET_KEY}" \
    "${GCE_NAT_DUO_API_HOSTNAME}"

  __write_librato_config \
    "${GCE_NAT_LIBRATO_EMAIL}" \
    "${GCE_NAT_LIBRATO_TOKEN}"

  __expand_nat_tbz2
  __setup_nat_forwarding
  __setup_nat_conntracker
  __setup_gesund
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

__expand_nat_tbz2() {
  local nattbz2="${VARTMP}/nat.tar.bz2"

  if [[ ! -f "${nattbz2}" ]]; then
    return
  fi

  tar --no-same-permissions --strip-components=1 -C / -xvf "${nattbz2}"
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

__setup_nat_conntracker() {
  local ncc="${VARTMP}/nat-conntracker-confs"
  local conf="${ETCDIR}/default/nat-conntracker"
  local service_dest="${ETCDIR}/systemd/system/nat-conntracker.service"
  local wrapper_dest="${USRLOCAL}/bin/nat-conntracker-wrapper"

  eval "$(travis-combined-env nat-conntracker)"

  local nc_self_image="${GESUND_SELF_IMAGE:-travisci/nat-conntracker}"

  docker run \
    --rm \
    "${nc_self_image}" \
    nat-conntracker --print-wrapper >"${wrapper_dest}"
  chmod +x "${wrapper_dest}"

  if [[ -d "$(dirname "${service_dest}")" ]]; then
    docker run \
      --rm \
      "${nc_self_image}" \
      nat-conntracker --print-service >"${service_dest}"
  fi

  apt-get update -y
  apt-get install -y fail2ban conntrack

  systemctl enable nat-conntracker || true
  systemctl start nat-conntracker || true

  systemctl enable fail2ban || true
  systemctl start fail2ban || true

  if [[ ! -d "${ncc}" ]]; then
    return
  fi

  cp -v "${ncc}/fail2ban-action-iptables-blocktype.local" \
    "${ETCDIR}/fail2ban/action.d/iptables-blocktype.local"

  cp -v "${ncc}/fail2ban-filter-nat-conntracker.conf" \
    "${ETCDIR}/fail2ban/filter.d/nat-conntracker.conf"

  cp -v "${ncc}/fail2ban-jail-nat-conntracker.conf" \
    "${ETCDIR}/fail2ban/jail.d/nat-conntracker.conf"

  cp -v "${ncc}/fail2ban.local" \
    "${ETCDIR}/fail2ban/fail2ban.local"

  systemctl restart fail2ban || true
}

__setup_gesund() {
  local service_dest="${ETCDIR}/systemd/system/gesund.service"
  local wrapper_dest="${USRLOCAL}/bin/gesund-wrapper"

  eval "$(travis-combined-env gesund)"

  local gesund_self_image="${GESUND_SELF_IMAGE:-travisci/gesund}"

  docker run \
    --rm \
    "${gesund_self_image}" \
    gesund --print-wrapper >"${wrapper_dest}"
  chmod +x "${wrapper_dest}"

  if [[ -d "$(dirname "${service_dest}")" ]]; then
    docker run \
      --rm \
      "${gesund_self_image}" \
      gesund --print-service >"${service_dest}"

    systemctl enable gesund || true
    systemctl start gesund || true
  fi
}

__fetch_region_zone() {
  curl -s -H 'Metadata-Flavor: Google' \
    http://metadata.google.internal/computeMetadata/v1/instance/zone |
    awk -F/ '{ print $NF }'
}

main "${@}"
