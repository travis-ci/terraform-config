ensure_tfw() {
  : "${TMPDIR:=/var/tmp}"
  : "${USRLOCALDIR:=/usr/local}"

  apt-get update -yqq
  apt-get install -yqq curl
  curl -sSL \
    -o "${TMPDIR}/tfw" \
    'https://raw.githubusercontent.com/travis-ci/tfw/master/tfw'
  chmod +x "${TMPDIR}/tfw"
  mv -v "${TMPDIR}/tfw" "${USRLOCALDIR}/bin/tfw"
}

ensure_tfw
