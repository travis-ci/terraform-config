#!/usr/bin/env bash
set -o errexit

terraform_user_bootstrap() {
  set -o xtrace

  : "${VARTMP:=/var/tmp}"
  : "${ETCSUDOERSD:=/etc/sudoers.d}"

  if ! getent passwd terraform &>/dev/null; then
    useradd terraform
  fi

  usermod -a -G sudo terraform
  echo "terraform:${TRAVIS_INSTANCE_TERRAFORM_PASSWORD}" | chpasswd || true

  cat >"${ETCSUDOERSD}/terraform" <<EOSUDOERS
terraform ALL=(ALL) NOPASSWD:ALL
EOSUDOERS
  chown root:root "${ETCSUDOERSD}/terraform"
  chmod 0600 "${ETCSUDOERSD}/terraform"

  mkdir -p ~terraform/.ssh

  if [[ -f "${VARTMP}/terraform_rsa.pub" ]]; then
    cp -v "${VARTMP}/terraform_rsa.pub" ~terraform/.ssh/authorized_keys
    cp -v "${VARTMP}/terraform_rsa.pub" ~terraform/.ssh/id_rsa.pub
    chmod 0644 ~terraform/.ssh/authorized_keys
    chmod 0644 ~terraform/.ssh/id_rsa.pub
  fi

  if [[ -f "${VARTMP}/terraform_rsa" ]]; then
    cp -v "${VARTMP}/terraform_rsa" ~terraform/.ssh/id_rsa
    chmod 0400 ~terraform/.ssh/id_rsa
    rm "${VARTMP}/terraform_rsa"
  fi

  chown -R terraform ~terraform/
  chmod 0700 ~terraform/.ssh
}

terraform_user_bootstrap
