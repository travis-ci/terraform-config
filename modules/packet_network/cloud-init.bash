#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  if [[ ! "${QUIET}" ]]; then
    set -o xtrace
  fi

  logger 'msg="beginning cloud-init fun"'

  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${USRLOCAL:=/usr/local}"
  : "${VARTMP:=/var/tmp}"

  chown nobody:nogroup "${VARTMP}"
  chmod 0777 "${VARTMP}"

  export DEBIAN_FRONTEND=noninteractive

  __install_packages
  __install_tfw
  __extract_tfw_files
  __run_tfw_bootstrap
  __disable_unfriendly_services

  for substep in \
    travis_user \
    terraform_user \
    sysctl \
    networking \
    duo \
    raid; do
    logger "msg=\"running setup\" substep=\"${substep}\""
    "__setup_${substep}"
  done
}

__install_packages() {
  for key in autosave_v{4,6}; do
    echo "iptables-persistent iptables-persistent/${key} boolean true" |
      debconf-set-selections
  done
  apt-get install -yqq iptables-persistent bzip2 curl
}

__install_tfw() {
  curl -sSL \
    -o "${VARTMP}/tfw" \
    'https://raw.githubusercontent.com/travis-ci/tfw/master/tfw'
  chmod +x "${VARTMP}/tfw"
  mv -v "${VARTMP}/tfw" "${USRLOCAL}/bin/tfw"
}

__extract_tfw_files() {
  if [[ ! -f "${VARTMP}/tfw.tar.bz2" ]]; then
    logger 'msg="no tfw tarball found; skipping extraction"'
    return
  fi

  tar \
    --no-same-permissions \
    --strip-components=1 \
    -C / \
    -xvf "${VARTMP}/tfw.tar.bz2"
}

__run_tfw_bootstrap() {
  if [[ -f "${VARTMP}/travis-tfw-bootstrap.bash" ]]; then
    logger "msg=\"found '${VARTMP}/travis-tfw-bootstrap.bash'\""
    bash "${VARTMP}/travis-tfw-bootstrap.bash"
  else
    logger "msg=\"running tfw admin-bootstrap\""
    tfw admin-bootstrap
  fi
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

__setup_travis_user() {
  if ! getent passwd travis &>/dev/null; then
    useradd travis
  fi

  chown -R travis:travis "${RUNDIR}"
}

__setup_terraform_user() {
  if ! getent passwd terraform &>/dev/null; then
    useradd terraform
  fi

  usermod -a -G sudo terraform

  mkdir -p ~terraform/.ssh
  chown -R terraform ~terraform/
  chmod 0700 ~terraform/.ssh

  if [[ -f "${VARTMP}/terraform_rsa.pub" ]]; then
    cp -v "${VARTMP}/terraform_rsa.pub" ~terraform/.ssh/authorized_keys
    chmod 0644 ~terraform/.ssh/authorized_keys
  fi
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
  eval "$(tfw printenv travis-network)"
  echo "${TRAVIS_NETWORK_ELASTIC_IP}"
}

__setup_duo() {
  if [[ ! -f "${ETCDIR}/duo/login_duo.conf" ]]; then
    logger 'No login_duo.conf found; skipping duo setup'
    return
  fi

  local sudo_users_string
  sudo_users_string="$(getent group sudo | awk -F: '{ print $NF }')"
  local sudo_users=()
  IFS=, read -a sudo_users <<<"${sudo_users_string}"

  for u in "${sudo_users[@]}"; do
    if [[ "${u}" == terraform ]]; then
      continue
    fi

    usermod -a -G duo "${u}"
  done
}

__setup_raid() {
  tfw admin-raid
}

main "$@"
