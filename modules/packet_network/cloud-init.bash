#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  __setup_travis_user
  __install_packages
  __setup_sysctl
  __setup_iptables
}

__setup_travis_user() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  if ! getent passwd travis &>/dev/null; then
    useradd travis
  fi

  chown -R travis:travis "${RUNDIR}"
}

__install_packages() {
  return
}

__setup_sysctl() {
  # NOTE: we do this mostly to ensure file IO chatty services like mysql will
  # play nicely with others, such as when multiple containers are running mysql,
  # which is the default on precise + trusty.  The value we set here is 16^5,
  # which is one power higher than the default of 16^4 :sparkles:.
  sysctl -w fs.aio-max-nr=1048576

  sysctl
}

__setup_iptables() {
  return
}

main "$@"
