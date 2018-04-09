#!/usr/bin/env bash
set -o errexit

main() {
  set -o xtrace

  : "${VARTMP:=/var/tmp}"
  : "${ETCSUDOERSD:=/etc/sudoers.d}"

  if ! getent passwd terraform &>/dev/null; then
    useradd terraform
  fi

  usermod -a -G sudo terraform

  cat >"${ETCSUDOERSD}/terraform" <<EOSUDOERS
terraform ALL=(ALL) NOPASSWD:ALL
EOSUDOERS
  chown root:root "${ETCSUDOERSD}/terraform"
  chmod 0600 "${ETCSUDOERSD}/terraform"

  mkdir -p ~terraform/.ssh
  chown -R terraform ~terraform/
  chmod 0700 ~terraform/.ssh

  if [[ -f "${VARTMP}/terraform_rsa.pub" ]]; then
    cp -v "${VARTMP}/terraform_rsa.pub" ~terraform/.ssh/authorized_keys
    chmod 0644 ~terraform/.ssh/authorized_keys
  fi
}

main "${@}"
