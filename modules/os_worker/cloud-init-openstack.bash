#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"
  : "${TMP:=/tmp}"
  : "${GO_VERSION:=1.9.2}"
  : "${GOPATH:="${TMP}/go-workspace"}"

  __install_go
  __build_travis_worker
  __start_worker_service
}

__start_worker_service() {
  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    cp -v "${VARTMP}/travis-worker.service" \
      "${ETCDIR}/systemd/system/travis-worker.service"
    systemctl enable "travis-worker" || true
    systemctl start "travis-worker" || true
  fi
}
__install_go() {
  if [ ! -f "${TMP}/go${GO_VERSION}.linux-ppc64le.tar.gz" ]; then
    wget -P "${TMP}" "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-ppc64le.tar.gz"
  fi
  if [ ! -f /usr/local/bin/go ]; then
    tar -C "${TMP}" -xf "${TMP}/go${GO_VERSION}.linux-ppc64le.tar.gz"
    mv "${TMP}/go" /usr/local
  fi
}

__build_travis_worker() {

  export GOPATH
  PATH=${PATH}:/usr/local/go/bin
  PATH=${PATH}:$(go env GOPATH)/bin
  export PATH

  if [ ! -f "${GOPATH}/bin/travis-worker" ]; then
    mkdir -p "${GOPATH}/src/github.com/travis-ci"
    if [ ! -d "${GOPATH}/src/github.com/travis-ci/worker" ]; then
      git clone https://github.com/travis-ci/worker "${GOPATH}/src/github.com/travis-ci/worker"
    fi
    cd "${GOPATH}/src/github.com/travis-ci/worker" || exit

    go get -u github.com/FiloSottile/gvt
    go get -u github.com/alecthomas/gometalinter
    go get -u mvdan.cc/sh/cmd/shfmt
    gometalinter --install
    apt-get update && apt-get -y install shellcheck build-essential

    make deps
    make build
  fi

  if [ -f "${GOPATH}/bin/travis-worker" ]; then
    cp "${GOPATH}/bin/travis-worker" /usr/local/bin/travis-worker
  fi
}

main "$@"
