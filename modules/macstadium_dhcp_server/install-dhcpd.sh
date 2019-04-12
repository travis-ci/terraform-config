#!/bin/bash
set -o errexit

main() {
  #grab the dhcp server package
  sudo yum install -y dhcp

  # Configure dhcpd
  sudo mv "/tmp/dhcpd.conf" "/etc/dhcp/dhcpd.conf"

  # Start and enable the service
  sudo systemctl enable dhcpd
  sudo systemctl start dhcpd
}

main "$@"
