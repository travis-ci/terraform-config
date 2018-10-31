#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
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
    randcreds \
    worker; do
    logger running setup substep="${substep}"
    "__setup_${substep}"
  done
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
  "${VARLIBDIR}/cloud/scripts/per-boot/00-ensure-tfw" || true

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

  if ! getent group docker &>/dev/null; then
    groupadd docker
  fi

  usermod -a -G docker travis
  chown -R travis:travis "${RUNDIR}"
}

__setup_sysctl() {
  echo 1048576 >/proc/sys/fs/aio-max-nr
  sysctl -w fs.aio-max-nr=1048576
}

__setup_randcreds() {
  if [[ ! -f "${VARTMP}/gce_accounts_b64.txt" ]]; then
    return
  fi

  tfw randline \
    -d \
    -i "${VARTMP}/gce_accounts_b64.txt" \
    -o "${VARTMP}/gce.json"

  chown travis:travis "${VARTMP}/gce.json"
}

__setup_worker() {
  tfw gsub travis-worker "${VARTMP}/travis-worker.env.tmpl" \
    "${ETCDIR}/default/travis-worker"
  tfw gsub travis-worker "${VARTMP}/travis-worker-cloud-init.env.tmpl" \
    "${ETCDIR}/default/travis-worker-cloud-init"

  eval "$(tfw printenv travis-worker)"

  __wait_for_docker

  tfw extract travis-worker "${TRAVIS_WORKER_SELF_IMAGE}"

  systemctl enable travis-worker || true
  systemctl start travis-worker || true
}

main "$@"
