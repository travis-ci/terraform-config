#!/usr/bin/env bash
set -o errexit

ensure_tfw() {
  : "${TMPDIR:=/var/tmp}"
  : "${USRLOCALDIR:=/usr/local}"

  apt-get update -yqq
  apt-get install -yqq curl make

  rm -rf "${TMPDIR}/tfw-install"
  mkdir -p "${TMPDIR}/tfw-install"
  curl -sSL https://api.github.com/repos/travis-ci/tfw/tarball/master |
    tar -C "${TMPDIR}/tfw-install" --strip-components=1 -xzf -
  make -C "${TMPDIR}/tfw-install" install PREFIX="${USRLOCALDIR}"
}

ensure_tfw
