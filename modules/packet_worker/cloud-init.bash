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

  __install_tfw
  __run_tfw_bootstrap
  __install_packages
  __extract_tfw_files

  # FIXME: re-enable at some point after initial setup?
  systemctl stop fail2ban || true

  for substep in \
    travis_user \
    terraform_user \
    sysctl \
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

__ensure_docker() {
  if docker version &>/dev/null; then
    return
  fi
  curl -Ls https://get.docker.io | bash
}

__install_packages() {
  apt-get install -yqq \
    bzip2 \
    curl \
    libpam-cap \
    zsh
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
  chown -R root:root "${ETCDIR}/sudoers" "${ETCDIR}/sudoers.d"
}

__run_tfw_bootstrap() {
  logger "msg=\"running tfw bootstrap\""
  tfw bootstrap
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
}

__setup_raid() {
  logger "msg=\"running tfw admin-raid\""
  tfw admin-raid
}

__setup_worker() {
  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    cp -v "${VARTMP}/travis-worker.service" \
      "${ETCDIR}/systemd/system/travis-worker.service"
    systemctl enable travis-worker || true
  fi

  systemctl stop travis-worker || true
  systemctl start travis-worker || true
}

main "$@"
