#!/bin/bash

# Create vsphere-monitor user if it doesn't exist
if ! getent passwd vsphere-monitor >/dev/null; then
  sudo useradd -r -s /usr/bin/nologin vsphere-monitor
fi

# Move configuration into place and correct permissions
sudo mv /tmp/etc-default-vsphere-monitor /etc/default/vsphere-monitor
sudo chown vsphere-monitor:vsphere-monitor /etc/default/vsphere-monitor
sudo chmod 0600 /etc/default/vsphere-monitor

# Configure upstart
sudo mkdir -p /var/tmp/run/vsphere-monitor
sudo chown vsphere-monitor:vsphere-monitor /var/tmp/run/vsphere-monitor
sudo mv /tmp/init-vsphere-monitor.conf /etc/init/vsphere-monitor.conf

# Install the binary
sudo wget -O /usr/local/bin/vsphere-monitor "https://s3.amazonaws.com/travis-ci-vsphere-monitor-artifacts/travis-ci/vsphere-monitor/${version}/build/linux/amd64/vsphere-monitor"
sudo chmod 0755 /usr/local/bin/vsphere-monitor
