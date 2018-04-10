#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  if [[ ! "${QUIET}" ]]; then
    set -o xtrace
  fi

  logger 'msg="beginning cloud-init fun"'

  : "${DEV:=/dev}"
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${VARTMP:=/var/tmp}"

  export DEBIAN_FRONTEND=noninteractive
  chown nobody:nogroup "${VARTMP}"
  chmod 0777 "${VARTMP}"

  mkdir -p "${RUNDIR}"
  echo "___INSTANCE_ID___-$(hostname)" >"${RUNDIR}/instance-hostname.tmpl"

  for substep in \
    tfw \
    travis_user \
    sysctl \
    networking \
    raid \
    worker; do
    logger "msg=\"running setup\" substep=\"${substep}\""
    "__setup_${substep}"
  done

  __wait_for_docker
}

__wait_for_docker() {
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    start docker &>/dev/null || true
    sleep 10
    let i+=10
  done
}

__setup_tfw() {
  curl -sSL \
    -o "${VARTMP}/tfw" \
    'https://raw.githubusercontent.com/travis-ci/tfw/master/tfw'
  chmod +x "${VARTMP}/tfw"
  mv -v "${VARTMP}/tfw" "${USRLOCAL}/bin/tfw"

  logger "msg=\"running tfw bootstrap\""
  tfw bootstrap

  if [[ -f "${VARTMP}/tfw.tar.bz2" ]]; then
    tar \
      --no-same-permissions \
      --strip-components=1 \
      -C / \
      -xvf "${VARTMP}/tfw.tar.bz2"
  fi

  chown -R root:root "${ETCDIR}/sudoers" "${ETCDIR}/sudoers.d"

  logger "msg=\"running tfw admin-bootstrap\""
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
  travis-packet-privnet-setup
}

__setup_raid() {
  logger "msg=\"running tfw admin-raid\""
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

  systemctl stop travis-worker || true
  systemctl start travis-worker || true
}

main "$@"
