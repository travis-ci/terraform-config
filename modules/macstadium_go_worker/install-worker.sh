#!/bin/bash

# Create travis-worker user if it doesn't exist
if ! getent passwd travis-worker >/dev/null; then
    sudo useradd -r -s /usr/bin/nologin travis-worker
fi

# Move configuration into place and correct permissions
sudo mv /tmp/etc-default-travis-worker-${env} /etc/default/travis-worker-${env}
sudo chown travis-worker /etc/default/travis-worker-${env}
sudo chmod 0600 /etc/default/travis-worker-${env}

# Move the SSH key in place and correct permissions
sudo mv /tmp/travis-vm-ssh-key /etc/travis-vm-ssh-key
sudo chown travis-worker /etc/travis-vm-ssh-key
sudo chmod 0600 /etc/travis-vm-ssh-key

# Configure upstart
sudo mkdir -p /var/tmp/run/travis-worker
sudo chown travis-worker /var/tmp/run/travis-worker
sudo mv /tmp/init-travis-worker-${env}.conf /etc/init/travis-worker-${env}.conf

# Install the binary
sudo wget -O /usr/local/bin/travis-worker-${env} https://s3.amazonaws.com/travis-worker-artifacts/travis-ci/worker/${version}/build/linux/amd64/travis-worker
sudo chmod 755 /usr/local/bin/travis-worker-${env}
