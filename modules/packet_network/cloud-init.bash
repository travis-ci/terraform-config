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
  __setup_duo
}

__setup_travis_user() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  if ! getent passwd travis &>/dev/null; then
    useradd travis
  fi

  chown -R travis:travis "${RUNDIR}"
}

__install_packages() {
  for key in autosave_v{4,6}; do
    echo "iptables-persistent iptables-persistent/${key} boolean true" |
      debconf-set-selections
  done
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
    if ip address add "${elastic_ip}/32" dev lo; then
      iptables -t nat -A POSTROUTING -o "${pub_iface}" -j SNAT --to "${elastic_ip}"
    fi
  fi

  iptables -t nat -S POSTROUTING | if ! grep -q MASQUERADE; then
    iptables -t nat -A POSTROUTING -o "${pub_iface}" -j MASQUERADE
  fi

  iptables -S FORWARD | if ! grep -q conntrack; then
    iptables -A FORWARD -i "${pub_iface}" -o "${priv_iface}" \
      -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  fi

  iptables -S FORWARD | if ! grep -q "i ${priv_iface} -o ${pub_iface}"; then
    iptables -A FORWARD -i "${priv_iface}" -o "${pub_iface}" -j ACCEPT
  fi
}

__find_private_interface() {
  local iface=enp1s0f1
  iface="$(
    ip -o addr show | grep -E 'inet 10\.' |
      grep -v bond | awk '{ print $2 }' | head -n 1
  )"
  echo "${iface:-enp1s0f1}"
}

__find_public_interface() {
  local iface=bond0
  iface="$(ip -o addr show | grep -vE 'inet (172|127|10|192)\.' | grep -v inet6 |
    awk '{ print $2 }' | grep -v '^lo$' | head -n 1)"
  echo "${iface:-bond0}"
}

__find_elastic_ip() {
  eval "$(travis-tfw-combined-env travis-network)"
  echo "${TRAVIS_NETWORK_ELASTIC_IP}"
}

__setup_duo() {
  : "${ETCDIR:=/etc}"
  if [[ ! -f "${ETCDIR}/duo/login_duo.conf" ]]; then
    logger 'No login_duo.conf found; skipping duo setup'
    return
  fi

  if grep -qE 'ForceCommand.*login_duo' "${ETCDIR}/ssh/sshd_config"; then
    logger 'sshd already configured with login_duo'
    return
  fi

  echo 'ForceCommand /usr/sbin/login_duo' >>"${ETCDIR}/ssh/sshd_config"
  service sshd restart
}

main "$@"
