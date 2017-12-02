#!/usr/bin/env bash
set -o errexit
shopt -s nullglob

main() {
  : "${PACKER_BUILDER_TYPE:=packet}"
  : "${PACKER_TEMPLATES_BASE_URL:=https://raw.githubusercontent.com/travis-ci/packer-templates}"
  : "${PACKER_TEMPLATES_BRANCH:=master}"
  : "${TMPDIR:=/tmp}"

  export DEBIAN_FRONTEND=noninteractive
  export PACKER_BUILDER_TYPE

  apt-get update -yqq
  apt-get install -yqq curl software-properties-common

  local bootstrap_url="${PACKER_TEMPLATES_BASE_URL}/${PACKER_TEMPLATES_BRANCH}"
  bootstrap_url="${bootstrap_url}/packer-scripts/pre-chef-bootstrap"

  curl -sSL -o "${TMPDIR}/pre-chef-bootstrap.bash" "${bootstrap_url}"
  "${TMPDIR}/pre-chef-bootstrap.bash"

  local tfwce_url="${PACKER_TEMPLATES_BASE_URL}/${PACKER_TEMPLATES_BRANCH}"
  tfwce_url="${tfwce_url}/cookbooks/travis_tfw/files"
  tfwce_url="${tfwce_url}/default/travis-tfw-combined-env"

  curl -sSL -o /usr/local/bin/travis-tfw-combined-env "${tfwce_url}"
  chmod 0755 /usr/local/bin/travis-tfw-combined-env
  ln -s \
    /usr/local/bin/travis-tfw-combined-env \
    /usr/local/bin/travis-combined-env

  logger 'Setting up internal base'
  __setup_internal_base
}

__setup_internal_base() {
  : "${RUN_DIR:=/var/tmp/travis-run.d}"

  mkdir -p "${RUN_DIR}"
  chown -R travis:travis "${RUN_DIR}"

  for substep in apt openssh papertrail sudo packages cloudcfg duo; do
    logger "msg=\"setting up internal base\" substep=\"${substep}\""
    "__setup_internal_base_${substep}"
  done
}

__setup_internal_base_apt() {
  if ! apt-get --version &>/dev/null; then
    logger 'No apt-get found; skipping base apt setup'
    return
  fi

  apt-get update -yqq
  touch '/var/lib/apt/periodic/update-success-stamp'

  for d in /var/cache/local /var/cache/local/preseeding; do
    mkdir -p "${d}"
    chown root:root "${d}"
    chmod 0755 "${d}"
  done

  apt-get install -yqq apt-transport-https
}

__setup_internal_base_openssh() {
  apt-get install -yqq openssh-client openssh-server
}

__setup_internal_base_papertrail() {
  : "${ETC_DIR:=/etc}"
  : "${VAR_SPOOL:=/var/spool}"
  : "${VAR_LOG:=/var/log}"
  : "${VAR_TMP:=/var/tmp}"
  local rsyslog_d="${ETC_DIR}/rsyslog.d"
  local rsyslog_conf="${ETC_DIR}/rsyslog.conf"
  local working_dir="${VAR_SPOOL}/rsyslog"
  local papertrail_ca="${ETC_DIR}/papertrail-bundle.pem"
  local papertrail_ca_url='https://papertrailapp.com/tools/papertrail-bundle.pem'

  curl -sSL -o "${papertrail_ca}" "${papertrail_ca_url}"
  chmod 0444 "${papertrail_ca}"

  apt-get install -yqq rsyslog
  apt-get install -yqq rsyslog-gnutls

  mkdir -p "${rsyslog_d}"
  chown -R root:root "${rsyslog_d}"
  chmod 0755 "${rsyslog_d}"

  mkdir -p "${working_dir}"
  chown -R root:adm "${working_dir}"
  chmod 0700 "${working_dir}"

  chown root:adm "${rsyslog_conf}" "${rsyslog_d}/"*.conf
  chmod 0644 "${rsyslog_conf}" "${rsyslog_d}/"*.conf

  rsyslogd -N 1 -f "${rsyslog_conf}"
  service rsyslog restart
}

__setup_internal_base_sudo() {
  : "${ETC_DIR}/sudoers"
  local sudoers="${ETC_DIR}/sudoers"
  local sudoers_d="${ETC_DIR}/sudoers.d"

  apt-get install -yqq sudo

  chown root:root "${sudoers}"
  chmod 0440 "${sudoers}"

  mkdir -p "${sudoers_d}"
  chown root:root "${sudoers_d}"
  chmod 0750 "${sudoers_d}"

  chown root:root "${sudoers_d}/90-group-sudo"
  chmod 0440 "${sudoers_d}/90-group-sudo"
}

__setup_internal_base_packages() {
  apt-get install -yqq fail2ban iptables-persistent whois zsh pssh
}

__setup_internal_base_cloudcfg() {
  : "${ETC_DIR:=/etc}"
  : "${VAR_LIB:=/var/lib}"
  local cloud_d="${ETC_DIR}/cloud"
  local cloud_scripts_per_boot="${VAR_LIB}/cloud/scripts/per-boot"
  local script_base_url
  script_base_url='https://raw.githubusercontent.com/travis-ci'
  script_base_url="${script_base_url}/packer-templates/master/cookbooks"
  script_base_url="${script_base_url}/travis_internal_base/files/default"

  mkdir -p "${cloud_d}"
  chown root:root "${cloud_d}"
  chmod 0755 "${cloud_d}"

  for f in 00-create-users \
    00-disable-travis-sudo \
    10-configure-fail2ban-ssh \
    10-generate-ssh-host-keys \
    10-set-hostname-from-template \
    50-update-rsyslog-papertrail-config; do
    curl -sSL -o "${cloud_scripts_per_boot}/${f}"
    chown root:root "${cloud_scripts_per_boot}/${f}"
    chmod 0755 "${cloud_scripts_per_boot}/${f}"
  done
}

__setup_internal_base_duo() {
  : "${DUO_CONF:=/var/tmp/duo.conf}"

  if [[ ! -f "${DUO_CONF}" ]]; then
    logger 'No duo conf found; skipping duo setup'
    return
  fi

  : "${ETC_DIR:=/etc}"
  local pam_d="${ETC_DIR}/pam.d"
  local conf_base_url
  conf_base_url='https://raw.githubusercontent.com/travis-ci'
  conf_base_url="${conf_base_url}/packer-templates/master/cookbooks"
  conf_base_url="${conf_base_url}/travis_internal_base/templates/default"
  local dist
  dist="$(lsb_release -sc)"

  apt-get install -yqq libssl-dev libpam-dev
  apt-add-repository -y "deb http://pkg.duosecurity.com/Ubuntu ${dist} main"
  curl -sSL https://duo.com/APT-GPG-KEY-DUO | apt-key add -
  apt-get update -yqq
  apt-get install -y duo-unix

  for conf in sshd common-auth; do
    curl -sSL -o "${pam_d}/${conf}" \
      "${conf_base_url}/pam.d-${conf}.conf.erb"
    chmod 0600 "${pam_d}/${conf}"
  done

  chown -R sshd:root "${pam_d}"

  local duo_conf_dest

  for conf in pam login; do
    duo_conf_dest="${ETC_DIR}/duo/${conf}_duo.conf"
    cp -v "${DUO_CONF}" "${duo_conf_dest}"
    chown root:root "${duo_conf_dest}"
    chmod 0600 "${duo_conf_dest}"
  done
}

main "$@"
