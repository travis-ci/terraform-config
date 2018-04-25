#!/usr/bin/env bash
set -o errexit

maybe_reboot() {
  : "${FIRSTBOOT:=/.first-boot}"

  if [[ -s "${FIRSTBOOT}" ]]; then
    logger first boot detected: $(cat "${FIRSTBOOT}")
    return
  fi

  date -u >"${FIRSTBOOT}"
  systemctl reboot
}

maybe_reboot
