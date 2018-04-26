#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  if [[ ! "${QUIET}" ]]; then
    set -o xtrace
  fi

  logger beginning dynamic config fun

  : "${DEV:=/dev}"
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${VARLIBDIR:=/var/lib}"
  : "${VARLOGDIR:=/var/log}"
  : "${VARTMP:=/var/tmp}"

  export DEBIAN_FRONTEND=noninteractive
  chown nobody:nogroup "${VARTMP}"
  chmod 0777 "${VARTMP}"

  for substep in \
    tfw \
    travis_user \
    sysctl \
    networking \
    raid \
    worker \
    refail2ban; do
    logger running setup substep="${substep}"
    "__setup_${substep}"
  done

  systemctl start fail2ban || true
}

__wait_for_docker() {
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    systemctl start docker &>/dev/null || true
    sleep 10
    let i+=10
  done
}

__setup_tfw() {
  logger running tfw bootstrap
  tfw bootstrap

  chown -R root:root "${ETCDIR}/sudoers" "${ETCDIR}/sudoers.d"

  logger running tfw admin-bootstrap
  tfw admin-bootstrap

  systemctl restart sshd || true
}

__setup_travis_user() {
  if ! getent passwd travis &>/dev/null; then
    useradd travis
  fi

  usermod -a -G docker travis
  chown -R travis:travis "${RUNDIR}"
}

__setup_sysctl() {
  echo 1048576 >/proc/sys/fs/aio-max-nr
  sysctl -w fs.aio-max-nr=1048576
}

__setup_networking() {
  for key in autosave_v{4,6}; do
    echo "iptables-persistent iptables-persistent/${key} boolean true" |
      debconf-set-selections
  done

  apt-get install -yqq iptables-persistent

  "${VARLIBDIR}/cloud/scripts/per-boot/00-travis-packet-privnet-setup" || true

  # Reject any forwarded packets destined for the Packet metadata API
  if ! iptables -C FORWARD -d 192.80.8.124 -j REJECT; then
    iptables -I FORWARD -d 192.80.8.124 -j REJECT
  fi
}

__setup_raid() {
  logger running tfw admin-raid
  tfw admin-raid
}

__setup_worker() {
  eval "$(tfw printenv travis-worker)"
  tfw extract travis-worker "${TRAVIS_WORKER_SELF_IMAGE}"

  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    cp -v "${VARTMP}/travis-worker.service" \
      "${ETCDIR}/systemd/system/travis-worker.service"
    systemctl enable travis-worker || true
  fi

  __wait_for_docker
  systemctl start travis-worker || true
}

__setup_refail2ban() {
  apt-get install -yqq sqlite3

  if [[ -f "${VARLIBDIR}/fail2ban/fail2ban.sqlite3" ]]; then
    sqlite3 "${VARLIBDIR}/fail2ban/fail2ban.sqlite3" 'DELETE FROM bans' || true
  fi

  cp -v "${VARLOGDIR}/auth.log" "${VARLOGDIR}/auth.log.$(date +%s)" || true
  echo >"${VARLOGDIR}/auth.log"

  systemctl start fail2ban || true
}

main "$@"
