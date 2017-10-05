#!/bin/bash
set -o errexit

main() {
  # declared for shellcheck
  local env version

  # Create vsphere-janitor user if it doesn't exist
  if ! getent passwd vsphere-janitor >/dev/null; then
    sudo useradd -r -s /usr/bin/nologin vsphere-janitor
  fi

  # Move configuration into place and correct permissions
  sudo mv "/tmp/etc-default-vsphere-janitor-${env}" "/etc/default/vsphere-janitor-${env}"
  sudo chown vsphere-janitor:vsphere-janitor "/etc/default/vsphere-janitor-${env}"
  sudo chmod 0600 "/etc/default/vsphere-janitor-${env}"

  # Configure upstart
  sudo mkdir -p /var/tmp/run/vsphere-janitor
  sudo chown vsphere-janitor:vsphere-janitor /var/tmp/run/vsphere-janitor
  sudo mv "/tmp/init-vsphere-janitor-${env}.conf" "/etc/init/vsphere-janitor-${env}.conf"

  # Install the binary
  sudo wget -O "/usr/local/bin/vsphere-janitor-${env}" "https://s3.amazonaws.com/travis-ci-vsphere-janitor-artifacts/travis-ci/vsphere-janitor/${version}/build/linux/amd64/vsphere-janitor"
  sudo chmod 755 "/usr/local/bin/vsphere-janitor-${env}"
}

main "$@"
