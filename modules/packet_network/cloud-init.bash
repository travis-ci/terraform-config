#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  if [[ ! "${QUIET}" ]]; then
    set -o xtrace
  fi

  : "${RUNDIR:=/var/tmp/travis-run.d}"

  __setup_travis_user
  __install_packages
  __setup_sysctl
  __setup_networking

  hostname >"${RUNDIR}/instance-hostname.tmpl"
}

__setup_travis_user() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  if ! getent passwd travis &>/dev/null; then
    useradd travis
  fi

  chown -R travis:travis "${RUNDIR}"
}

__install_packages() {
  apt-get install -yqq iptables-persistent
}

__setup_sysctl() {
  echo 1048576 >/proc/sys/fs/aio-max-nr
  sysctl -w fs.aio-max-nr=1048576

  echo 1 >/proc/sys/net/ipv4/ip_forward
  sysctl -w net.ipv4.ip_forward=1
}

__setup_networking() {
  local pub_iface priv_iface elastic_ip
  pub_iface="$(__find_public_interface)"
  priv_iface="$(__find_private_interface)"
  elastic_ip="$(__find_elastic_ip)"

  if [[ -n "${elastic_ip}" ]]; then
    ip address add "${elastic_ip}/32" dev lo
    iptables -t nat -A POSTROUTING -o "${pub_iface}" -j SNAT --to "${elastic_ip}"
  fi
  iptables -t nat -A POSTROUTING -o "${pub_iface}" -j MASQUERADE
  iptables -A FORWARD -i "${pub_iface}" -o "${priv_iface}" \
    -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i "${priv_iface}" -o "${pub_iface}" -j ACCEPT
}

__find_private_interface() {
  local iface=enp2s0d1
  iface="$(ip -o addr show | grep 'inet 192' | awk '{ print $2 }')"
  echo "${iface:-enp2s0d1}"
}

__find_public_interface() {
  local iface=bond0
  iface="$(ip -o addr show | grep -vE 'inet (172|127|10|192)\.' | grep -v inet6 |
    awk '{ print $2 }' | grep -v '^lo$' | head -n 1)"
  echo "${iface:-bond0}"
}

__find_elastic_ip() {
  # FIXME: inject this from somewhere?
  local elastic_ip
  if [[ -f /etc/default/travis-network ]]; then
    # shellcheck source=/dev/null
    source /etc/default/travis-network
    elastic_ip="${TRAVIS_NETWORK_ELASTIC_IP}"
  fi

  echo "${elastic_ip}"
}

main "$@"
