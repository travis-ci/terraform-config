travis_packet_privnet_setup() {
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${TMPDIR:=/var/tmp}"

  local conf="${ETCDIR}/network/interfaces"
  local tmpconf="${TMPDIR}/network-interfaces.tmp"

  if [[ ! -f "${conf}" ]]; then
    logger 'no network interfaces config found; skipping net setup'
    return
  fi

  if ! grep -q '^  *bond-slaves' "${conf}"; then
    logger 'no bond-slaves detected; skipping net setup'
    return
  fi

  eval "$(tfw printenv travis-instance)"

  : "${TRAVIS_INSTANCE_INFRA_INDEX:=1}"

  eval "$(tfw printenv travis-network)"

  if [[ ! "${TRAVIS_NETWORK_VLAN_IP}" ]]; then
    local vlan_last_octet vlan_ip
    vlan_last_octet="$(
      ip -o addr | awk '/inet 10\.[^1][^0]/ {
      sub(/\/.*/, "", $4);
      sub(/.*\./, "", $4);
      print $4
    }'
    )"
    vlan_ip="192.168.${TRAVIS_INSTANCE_INFRA_INDEX}.${vlan_last_octet}"
    echo "export TRAVIS_NETWORK_VLAN_IP=${vlan_ip}" |
      tee -a "${ETCDIR}/default/travis-network-local"
  fi

  eval "$(tfw printenv travis-network)"

  : "${TRAVIS_NETWORK_VLAN_INTERFACE:=enp1s0f1}"
  : "${TRAVIS_NETWORK_VLAN_NETMASK:=255.255.255.0}"
  : "${TRAVIS_NETWORK_VLAN_IP:=192.168.1.$((RANDOM % 254))}"
  : "${TRAVIS_NETWORK_VLAN_GATEWAY:=}"

  if ! grep -q 'TRAVIS_NETWORK_VLAN_IP' \
    "${ETCDIR}/default/travis-network-local"; then
    echo "export TRAVIS_NETWORK_VLAN_IP=${TRAVIS_NETWORK_VLAN_IP}" |
      tee -a "${ETCDIR}/default/travis-network-local"
  fi

  awk "
  {
    if (\$0 ~ /bond-slaves/) {
      sub(/${TRAVIS_NETWORK_VLAN_INTERFACE}/, \"\", \$0);
      print \$0;
    } else if (\$0 ~ /iface ${TRAVIS_NETWORK_VLAN_INTERFACE}/) {
      sub(/manual/, \"static\", \$0);
      print \$0;

      # Eat any existing address, netmask, or gateway lines
      getline;
      getline;
      getline;

      print \"    address ${TRAVIS_NETWORK_VLAN_IP}\"
      print \"    netmask ${TRAVIS_NETWORK_VLAN_NETMASK}\"
    } else {
      print \$0;
    }
  }
  " <"${conf}" >"${tmpconf}"

  diff -u \
    --label "a/${conf}" "${conf}" \
    --label "b/${conf}" "${tmpconf}" || true

  cp -v "${tmpconf}" "${conf}"
  ifdown "${TRAVIS_NETWORK_VLAN_INTERFACE}" || true
  ifup "${TRAVIS_NETWORK_VLAN_INTERFACE}" || true

  if [[ "${TRAVIS_NETWORK_VLAN_GATEWAY}" ]]; then
    ip route replace default via \
      "${TRAVIS_NETWORK_VLAN_GATEWAY}" dev "${TRAVIS_NETWORK_VLAN_INTERFACE}"
  fi
}

travis_packet_privnet_setup
