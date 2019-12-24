#!/usr/bin/env bash

tee /etc/sysctl.d/99-lxd.conf &>/dev/null <<EOF
fs.inotify.max_queued_events = 4194304
fs.inotify.max_user_instances = 4194304
fs.inotify.max_user_watches = 4194304
fs.file-max = 1024000
vm.max_map_count = 262144
kernel.dmesg_restrict = 1
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv4.tcp_max_tw_buckets = 1440000
net.core.netdev_max_backlog = 182757
net.ipv4.tcp_mem = 182757 243679 365514
net.ipv4.tcp_max_syn_backlog = 3240000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_low_latency = 1
kernel.keys.maxkeys = 2000
kernel.pid_max = 1048576
net.core.somaxconn = 32768
EOF

tee /etc/rc.local &>/dev/null <<EOF
#!/bin/sh
echo 1 > /proc/sys/net/ipv4/ip_forward
modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
EOF

tee /etc/systemd/system/papertrail.service &>/dev/null <<EOF
[Unit]
Description=Papertrail
After=systemd-journald.service
Requires=systemd-journald.service

[Service]
ExecStart=/bin/sh -c "journalctl -f | ncat --ssl logs2.papertrailapp.com ${PAPERTRAIL_PORT}"
TimeoutStartSec=0
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

tee /usr/local/bin/setup-salt.sh &>/dev/null <<EOF
#!/bin/sh
set -eux
export PATH=/snap/bin/:${PATH}

apt update -yqq
apt install python3 -y
update-alternatives --install /usr/bin/python python /usr/bin/python3 10

curl -s -L https://bootstrap.saltstack.com -o install_salt.sh
sh install_salt.sh -x python3 -r -P git v2019.2.2
echo "master: ${SALT_MASTER}" > /etc/salt/minion
systemctl restart salt-minion.service

EOF

chmod +x /usr/local/bin/setup-salt.sh
/usr/local/bin/setup-salt.sh

tee /root/worker.env &>/dev/null <<EOF
# Pool size
export POOL_SIZE=${POOL_SIZE}

# Queue configuration
export TRAVIS_WORKER_AMQP_URI=${TRAVIS_WORKER_AMQP_URI}
export TRAVIS_WORKER_RABBITMQ_SHARDING=true
export TRAVIS_WORKER_BUILD_API_URI=${TRAVIS_WORKER_BUILD_API_URI}
export TRAVIS_WORKER_PROVIDER_NAME=${TRAVIS_WORKER_PROVIDER_NAME}
export TRAVIS_WORKER_QUEUE_NAME=${TRAVIS_WORKER_QUEUE_NAME}

# LXD configuration
export TRAVIS_WORKER_LXD_CPUS=2
export TRAVIS_WORKER_LXD_CPUS_BURST=true
export TRAVIS_WORKER_LXD_DOCKER_POOL=data
export TRAVIS_WORKER_LXD_IMAGE=ubuntu-18.04-slim
export TRAVIS_WORKER_LXD_NETWORK=1Gbit
export TRAVIS_WORKER_LXD_NETWORK_STATIC=true
export TRAVIS_WORKED_LXD_NETWORK_DNS=8.8.8.8,8.8.4.4,1.1.1.1,1.0.0.1

# Disk size
export TRAVIS_WORKER_LXD_DISK=${TRAVIS_WORKER_LXD_DISK}

# LXD image selector
export TRAVIS_WORKER_LXD_IMAGE_SELECTOR_TYPE=api
export TRAVIS_WORKER_LXD_IMAGE_SELECTOR_URL=${TRAVIS_WORKER_LXD_IMAGE_SELECTOR_URL}

# Librato
export TRAVIS_WORKER_LIBRATO_SOURCE=${TRAVIS_WORKER_LIBRATO_SOURCE}
export TRAVIS_WORKER_LIBRATO_EMAIL=${TRAVIS_WORKER_LIBRATO_EMAIL}
export TRAVIS_WORKER_LIBRATO_TOKEN=${TRAVIS_WORKER_LIBRATO_TOKEN}

EOF

tee /usr/local/bin/setup-worker.sh &>/dev/null <<EOF
#!/bin/sh
set -eux
export PATH=/snap/bin/:${PATH}

export DEBIAN_FRONTEND=noninteractive

apt update -yqq
apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

## Install snapd and other stuff
apt-get install snapd fail2ban linux-generic-hwe-18.04 htop iotop glances atop nmap -y
export PATH=/snap/bin/:$PATH

## Install and setup ZFS
apt-get install zfsutils-linux --yes
mkdir -p /mnt/data

## Install and setup LXD
apt-get remove --purge --yes lxd lxd-client liblxc1 lxcfs
snap install lxd
snap set lxd shiftfs.enable=true

lxc storage create instances zfs source=/dev/vdd volume.zfs.use_refquota=true
zfs set sync=disabled instances
zfs set atime=off instances

lxc storage create data dir source=/mnt/data

lxc network create lxdbr0 dns.mode=none ipv4.address=192.168.0.1/24 ipv4.dhcp=false ipv4.firewall=false ipv4.nat=true
## Common start logic: Failed to start device 'eth0': Cannot use security.ipv6_filtering as DHCPv6 is disabled or no IPv6 on parent lxdbr0 and no static IPv6 address set
lxc network set lxdbr0 ipv6.dhcp true
lxc network set lxdbr0 ipv6.address 2001:db8::1/64
lxc network set lxdbr0 ipv6.nat true

lxc profile device add default eth0 nic nictype=bridged parent=lxdbr0 security.mac_filtering=true
lxc profile device add default root disk path=/ pool=instances

## Setup worked
snap install travis-worker --edge
snap connect travis-worker:lxd lxd:lxd
mv /root/worker.env /var/snap/travis-worker/common/

## Tweak the kernel
##ln -sf /boot/vmlinux*5.3.0* /boot/vmlinuz
##ln -sf /boot/initrd*5.3.0* /boot/initrd.img

# execute rc.local
chmod +x /etc/rc.local

# Force reboot
shutdown -r
EOF

chmod 700 /usr/local/bin/setup-worker.sh

systemctl enable --now /etc/systemd/system/papertrail.service
/usr/local/bin/setup-worker.sh
