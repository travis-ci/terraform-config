#!/bin/bash
set -o errexit

main() {
  #grab the dhcp server package
  sudo apt-get update
  sudo apt-get install -y isc-dhcp-server

  # Configure dhcpd
  sudo mv "/tmp/dhcpd.conf" "/etc/dhcp/dhcpd.conf"

  # Configure dhcpd defaults
  sudo mv "/tmp/isc-dhcp-server-defaults" "/etc/default/isc-dhcp-server"
}

main "$@"
