#!/bin/bash

if ! getent passwd collectd-vsphere >/dev/null; then
  sudo useradd -r -s /usr/bin/nologin collectd-vsphere
fi

# add apt source, add gpg key, install necessary dependencies, and install collectd
echo "deb https://packagecloud.io/librato/librato-collectd/ubuntu/ trusty main" | sudo tee /etc/apt/sources.list.d/librato_librato-collectd.list > /dev/null
curl https://packagecloud.io/gpg.key 2> /dev/null | sudo apt-key add - #if you have a less reckless solution lmk
sudo apt-get update -yqq
sudo apt-get install -y debian-archive-keyring apt-transport-https
sudo apt-get install -y liboping0 snmp snmp-mibs-downloader
sudo apt-get install -y collectd

# put collectd configs in place
sudo mv "/tmp/collectd.conf" "/opt/collectd/etc/collectd.conf"
sudo chown root:root "/opt/collectd/etc/collectd.conf"
sudo chmod 644 "/opt/collectd/etc/collectd.conf"

sudo mv "/tmp/librato.conf" "/opt/collectd/etc/collectd.conf.d/librato.conf"
sudo chown root:root "/opt/collectd/etc/collectd.conf.d/librato.conf"
sudo chmod 644 "/opt/collectd/etc/collectd.conf.d/librato.conf"

sudo mv "/tmp/snmp.conf" "/opt/collectd/etc/collectd.conf.d/snmp.conf"
sudo chown root:root "/opt/collectd/etc/collectd.conf.d/snmp.conf"
sudo chmod 644 "/opt/collectd/etc/collectd.conf.d/snmp.conf"

sudo mv "/tmp/collectd-network-auth" "/opt/collectd/etc/collectd-network-auth"
sudo chown root:root "/opt/collectd/etc/collectd-network-auth"
sudo chmod 644 "/opt/collectd/etc/collectd-network-auth"

#put collectd-vsphere config in /etc/default
sudo mv "/tmp/etc-default-collectd-vsphere-${env}" "/etc/default/collectd-vsphere-${env}"
sudo chown root:root "/etc/default/collectd-vsphere-${env}"
sudo chmod 644 "/etc/default/collectd-vsphere-${env}"

#deploy collectd-vsphere upstart config
sudo mkdir -p /var/tmp/run/collectd-vsphere
sudo chown collectd-vsphere:collectd-vsphere /var/tmp/run/collectd-vsphere
sudo mv "/tmp/init-collectd-vsphere-${env}.conf" "/etc/init/collectd-vsphere-${env}.conf"
sudo chown root:root "/etc/init/collectd-vsphere-${env}"
sudo chmod 644 "/etc/init/collectd-vsphere-${env}"

# install collectd-vsphere binary
sudo wget -O "/usr/local/bin/collectd-vsphere-${env}" "https://s3.amazonaws.com/travis-ci-collectd-vsphere-artifacts/travis-ci/collectd-vsphere/${version}/build/linux/amd64/collectd-vsphere"
sudo chmod 755 "/usr/local/bin/collectd-vsphere-${env}"
