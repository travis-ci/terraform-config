#!/usr/bin/env bash
# vim:filetype=sh

write_files() {
  : "$${VARTMP:=/var/tmp}"
  : "$${ETCDIR:=/etc}"
  : "$${RUNDIR:=/var/tmp/travis-run.d}"

  mkdir -p "$${RUNDIR}"

  cat >"$${RUNDIR}/instance-hostname.tmpl"<<EOTMPL
___INSTANCE_NAME___.packet-___REGION_ZONE___.travisci.net
EOTMPL

  cat >"$${VARTMP}/terraform_rsa.pub" <<EOPUBKEY
${terraform_public_key_openssh}
EOPUBKEY

  cat >"$${ETCDIR}/default/travis-network" <<'EOENV'
export TRAVIS_NETWORK_NAT_IP=${nat_ip}
export TRAVIS_NETWORK_ELASTIC_IP=${elastic_ip}
export TRAVIS_NETWORK_VLAN_GATEWAY=${vlan_gateway}
EOENV

  cat >"$${ETCDIR}/default/travis-instance-cloud-init" <<'EOENV'
export TRAVIS_INSTANCE_FQDN=${instance_fqdn}
export TRAVIS_INSTANCE_INFRA_ENV=${env}
export TRAVIS_INSTANCE_INFRA_INDEX=${index}
export TRAVIS_INSTANCE_INFRA_NAME=packet
export TRAVIS_INSTANCE_INFRA_REGION=${facility}
export TRAVIS_INSTANCE_NAME=${instance_name}
export TRAVIS_INSTANCE_ROLE=nat
export TRAVIS_INSTANCE_TERRAFORM_PASSWORD=${terraform_password}
EOENV
}

write_files

source "$${ETCDIR}/default/travis-instance-cloud-init"

${file("${assets}/bits/ensure-tfw.bash")}

tfw bootstrap
systemctl stop fail2ban || true

${file("${assets}/bits/terraform-user-bootstrap.bash")}
${file("${assets}/bits/travis-packet-privnet-setup.bash")}
${file("${assets}/bits/maybe-reboot.bash")}
