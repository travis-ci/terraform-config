#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  [[ "${QUIET}" ]] || set -o xtrace

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
    squignix; do
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

__setup_squignix() {
  eval "$(tfw printenv squignix)"

  tfw extract squignix "${SQUIGNIX_IMAGE}"

  systemctl enable squignix || true
  systemctl start squignix || true
}

main "${@}"
