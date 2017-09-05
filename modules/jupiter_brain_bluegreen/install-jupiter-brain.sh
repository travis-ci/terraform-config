#!/bin/bash

set -e

# Create jupiter-brain user if it doesn't exist
if ! getent passwd jupiter-brain >/dev/null; then
  sudo useradd -r -s /usr/bin/nologin jupiter-brain
fi

# Move configuration into place and correct permissions
for file in "jupiter-brain-${env}"{,-blue,-green}; do
  sudo mv "/tmp/etc-default-$file" "/etc/default/$file"
  sudo chown jupiter-brain:jupiter-brain "/etc/default/$file"
  sudo chmod 0600 "/etc/default/$file"
done

# Configure upstart
sudo mkdir -p /var/tmp/run/jupiter-brain
sudo chown jupiter-brain:jupiter-brain /var/tmp/run/jupiter-brain
sudo mv "/tmp/init-jupiter-brain-${env}.conf" "/etc/init/jupiter-brain-${env}.conf"

# Install the binary
sudo wget -O "/usr/local/bin/jb-server-${env}" "https://s3.amazonaws.com/jupiter-brain-artifacts/travis-ci/jupiter-brain/${version}/build/linux/amd64/jb-server"
sudo chmod 755 "/usr/local/bin/jb-server-${env}"
