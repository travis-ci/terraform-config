#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  : "${ETCDIR:=/etc}"
  : "${TMPDIR:=/var/tmp}"
  : "${USRLOCAL:=/usr/local}"
  : "${VARTMP:=/var/tmp}"

  export DEBIAN_FRONTEND=noninteractive
  __disable_unfriendly_services
  __install_tfw

  eval "$(tfw printenv nat)"

  __expand_nat_tbz2
  __setup_gesund
  __write_librato_config "${GCE_NAT_LIBRATO_EMAIL}" "${GCE_NAT_LIBRATO_TOKEN}"
  __setup_nat_forwarding
  __setup_nat_conntracker
}

__disable_unfriendly_services() {
  systemctl stop apt-daily-upgrade || true
  systemctl disable apt-daily-upgrade || true
  systemctl stop apt-daily || true
  systemctl disable apt-daily || true
  systemctl stop apparmor || true
  systemctl disable apparmor || true
  systemctl reset-failed
}

__install_tfw() {
  apt-get update -yqq
  apt-get install -yqq curl make

  rm -rf "${TMPDIR}/tfw-install"
  mkdir -p "${TMPDIR}/tfw-install"
  curl -sSL https://api.github.com/repos/travis-ci/tfw/tarball/master |
    tar -C "${TMPDIR}/tfw-install" --strip-components=1 -xzf -
  make -C "${TMPDIR}/tfw-install" install PREFIX="${USRLOCAL}"
}

__write_librato_config() {
  if [[ ! "${1}" || ! "${2}" ]]; then
    return
  fi

  apt-get update -y
  apt-get install -y collectd collectd-utils

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

  iptables -t nat -S POSTROUTING | grep -v 172. | if ! grep -q MASQUERADE; then
    iptables -t nat -I POSTROUTING -o "${pub_iface}" -j MASQUERADE
  fi

  iptables -S FORWARD | grep -v docker |
    if ! grep -qE 'conntrack.+RELATED,ESTABLISHED'; then
      iptables -I FORWARD -o "${pub_iface}" \
        -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    fi

  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -t nat -P PREROUTING ACCEPT
  iptables -t nat -P INPUT ACCEPT
  iptables -t nat -P OUTPUT ACCEPT
  iptables -t nat -P POSTROUTING ACCEPT
}

__find_public_interface() {
  local iface=ens4
  iface="$(ip -o addr show | grep -vE 'inet (172|127)\.' | grep -v inet6 |
    awk '{ print $2 }' | grep -v '^lo$' | head -n 1)"
  echo "${iface:-ens4}"
}

__setup_nat_conntracker() {
  eval "$(tfw printenv nat-conntracker)"
  tfw extract nat-conntracker "${NAT_CONNTRACKER_SELF_IMAGE}"

  apt-get update -y
  apt-get install -y fail2ban conntrack

  systemctl enable nat-conntracker || true
  systemctl start nat-conntracker || true

  systemctl enable fail2ban || true
  systemctl start fail2ban || true

  local ncc="${VARTMP}/nat-conntracker-confs"

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
  eval "$(tfw printenv gesund)"
  tfw extract gesund "${GESUND_SELF_IMAGE}"

  systemctl enable gesund || true
  systemctl start gesund || true
}

__fetch_region_zone() {
  curl -s -H 'Metadata-Flavor: Google' \
    http://metadata.google.internal/computeMetadata/v1/instance/zone |
    awk -F/ '{ print $NF }'
}

main "${@}"
