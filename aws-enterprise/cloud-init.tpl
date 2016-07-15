#!/bin/bash

set -o errexit

ip link set eth0 mtu 1500

TRAVIS_ENTERPRISE_HOST="${enterprise_host_name}"
TRAVIS_ENTERPRISE_SECURITY_TOKEN="${rabbitmq_password}"
sed -i "s/\# export TRAVIS_ENTERPRISE_HOST=\"enterprise.yourhostname.corp\"/export TRAVIS_ENTERPRISE_HOST=\"$TRAVIS_ENTERPRISE_HOST\"/" /etc/default/travis-enterprise
sed -i "s/\# export TRAVIS_ENTERPRISE_SECURITY_TOKEN=\"abcd1234\"/export TRAVIS_ENTERPRISE_SECURITY_TOKEN=\"$TRAVIS_ENTERPRISE_SECURITY_TOKEN\"/" /etc/default/travis-enterprise

rm -rf /var/lib/cloud/instances/*

# Remove access to the EC2 metadata API
if ! iptables -t nat -C PREROUTING -p tcp -d 169.254.169.254 --dport 80 -j DNAT --to-destination 192.0.2.1; then
  iptables -t nat -I PREROUTING -p tcp -d 169.254.169.254 --dport 80 -j DNAT --to-destination 192.0.2.1
fi

# cronjob to shut down borked docker (linux kernel bug)
echo '* * * * * dmesg | grep -q unregister_netdevice && /sbin/shutdown -P now "unregister_netdevice detected, shutting down instance"' | crontab -
