#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${VARLIBDIR:=/var/lib}"
  : "${VARLOGDIR:=/var/log}"
  : "${ETCDIR:=/etc}"
  : "${TMPDIR:=/var/tmp}"
  : "${USRLOCAL:=/usr/local}"
  : "${VARTMP:=/var/tmp}"
  : "${BINDIR:=/usr/local/bin}"

  export DEBIAN_FRONTEND=noninteractive
  __disable_unfriendly_services
  __install_tfw

  eval "$(tfw printenv docker)"
  __setup_docker

  for substep in \
    tfw \
    travis_user \
    sysctl \
    randcreds \
    gcloud_cleanup; do
    logger running setup substep="${substep}"
    "__setup_${substep}"
  done
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

__setup_tfw() {
  "${VARLIBDIR}/cloud/scripts/per-boot/00-ensure-tfw" || true

  logger running tfw bootstrap
  tfw bootstrap

  chown -R root:root "${ETCDIR}/sudoers" "${ETCDIR}/sudoers.d"

  logger running tfw admin-bootstrap
  tfw admin-bootstrap

  systemctl restart sshd || true
}

__setup_docker() {
  apt-get update -yqq
  apt-get install -yqq docker.io
  systemctl stop docker.service || true

  if [[ -f "${VARTMP}/daemon-direct-lvm.json" ]]; then
    cp -v "${VARTMP}/daemon-direct-lvm.json" "${ETCDIR}/docker/"
    chmod 0644 "${ETCDIR}/docker/daemon-direct-lvm.json"
  fi
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
  local accounts_file="${VARTMP}/gce_accounts_b64.txt"
  if [[ ! -s "${accounts_file}" ]]; then
    return
  fi

  tfw randline -d -i "${accounts_file}" -o "${VARTMP}/gce.json"
  chown travis:travis "${VARTMP}/gce.json"
}

__setup_gcloud_cleanup() {
  tfw gsub gcloud-cleanup "${VARTMP}/travis-gcloud-cleanup.env.tmpl" \
    "${ETCDIR}/default/travis-gcloud-cleanup"
  tfw gsub gcloud-cleanup "${VARTMP}/travis-gcloud-cleanup-cloud-init.env.tmpl" \
    "${ETCDIR}/default/travis-gcloud-cleanup-cloud-init"

  eval "$(tfw printenv travis-gcloud-cleanup)"

  __wait_for_docker

  tfw extract gcloud-cleanup "${TRAVIS_GCLOUD_CLEANUP_SELF_IMAGE}"

  systemctl enable gcloud-cleanup || true
  systemctl start gcloud-cleanup || true
}

main "${@}"
