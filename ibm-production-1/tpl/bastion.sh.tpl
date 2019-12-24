#!/usr/bin/env bash

tee /usr/local/bin/setup-salt.sh &>/dev/null <<EOF
#!/bin/sh
set -eux
export PATH=/snap/bin/:${PATH}

apt update -yqq
apt install python3 -y

curl -s -L https://bootstrap.saltstack.com -o install_salt.sh
sh install_salt.sh -x python3 -r -M git v2019.2.2

echo "auto_accept: True" > /etc/salt/master

systemctl restart salt-master.service
EOF

chmod 700 /usr/local/bin/setup-salt.sh
/usr/local/bin/setup-salt.sh

tee /usr/local/bin/setup-bastion.sh &>/dev/null <<EOF
#!/bin/sh
set -eux
export PATH=/snap/bin/:${PATH}

apt -q update
apt -y upgrade
apt -y install htop iotop sysstat linux-generic-hwe-18.04 ruby awscli

## Install snapd
apt-get install snapd fail2ban -y
export PATH=/snap/bin/:${PATH}

## Tweak the kernel
#ln -sf /boot/vmlinuz*5.0.0* /boot/vmlinuz
#ln -sf /boot/initrd*5.0.0* /boot/initrd

# Force reboot
shutdown -r
EOF

chmod 700 /usr/local/bin/setup-bastion.sh

/usr/local/bin/setup-bastion.sh
