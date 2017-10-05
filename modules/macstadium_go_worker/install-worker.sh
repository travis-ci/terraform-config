#!/bin/bash
set -o errexit

main() {
  # declared for shellcheck
  local env version

  # Create travis-worker user if it doesn't exist
  if ! getent passwd travis-worker >/dev/null; then
    sudo useradd -r -s /usr/bin/nologin travis-worker
  fi

  # Move configuration into place and correct permissions
  sudo mv "/tmp/etc-default-travis-worker-${env}" "/etc/default/travis-worker-${env}"
  sudo chown travis-worker:travis-worker "/etc/default/travis-worker-${env}"
  sudo chmod 0600 "/etc/default/travis-worker-${env}"

  # Configure upstart
  sudo mkdir -p /var/tmp/run/travis-worker
  sudo chown travis-worker:travis-worker /var/tmp/run/travis-worker
  sudo mv "/tmp/init-travis-worker-${env}.conf" "/etc/init/travis-worker-${env}.conf"

  # Install the binary
  sudo wget -O "/usr/local/bin/travis-worker-${env}" "https://s3.amazonaws.com/travis-worker-artifacts/travis-ci/worker/${version}/linux/amd64/travis-worker"
  sudo chmod 755 "/usr/local/bin/travis-worker-${env}"
}

main "$@"
