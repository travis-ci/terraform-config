#!/usr/bin/env bash
set -o errexit

main() {
  : "${TMPDIR:=/tmp}"
  : "${PACKER_TEMPLATES_BRANCH:=master}"
  : "${PACKER_BUILDER_TYPE:=packet}"
  : "${PACKER_TEMPLATES_BASE_URL:=https://raw.githubusercontent.com/travis-ci/packer-templates}"
  : "${DUO_CONF:=/var/tmp/duo.conf}"

  export DEBIAN_FRONTEND=noninteractive
  export PACKER_BUILDER_TYPE

  apt-get update -yqq
  apt-get install -yqq curl

  local bootstrap_url="${PACKER_TEMPLATES_BASE_URL}/${PACKER_TEMPLATES_BRANCH}"
  bootstrap_url="${bootstrap_url}/packer-scripts/pre-chef-bootstrap"

  curl -sSL -o "${TMPDIR}/pre-chef-bootstrap.bash" "${bootstrap_url}"
  "${TMPDIR}/pre-chef-bootstrap.bash"

  local tfwce_url="${PACKER_TEMPLATES_BASE_URL}/${PACKER_TEMPLATES_BRANCH}"
  tfwce_url="${tfwce_url}/cookbooks/travis_tfw/files"
  tfwce_url="${tfwce_url}/default/travis-tfw-combined-env"

  curl -sSL -o /usr/local/bin/travis-tfw-combined-env "${tfwce_url}"
  chmod 0755 /usr/local/bin/travis-tfw-combined-env
  ln -s \
    /usr/local/bin/travis-tfw-combined-env \
    /usr/local/bin/travis-combined-env

  chown travis:travis /etc/default/travis-worker
  chown travis:travis /etc/default/travis-worker-cloud-init
  chown -R travis:travis /var/tmp/travis-run.d

  if [[ -f "${DUO_CONF}" ]]; then
    __setup_duo "${DUO_CONF}"
  fi
}

__setup_duo() {
  local conf="${1}"
}

main "$@"
