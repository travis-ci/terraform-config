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
  : "${GO_PATH:="${TMP}/go-workspace"}"

  __install_go
  __build_travis_worker
  __install_docker
  __start_docker_service
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
    wget -P ${TMP} "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-ppc64le.tar.gz"
  fi
  if [ ! -f /usr/local/bin/go ]; then
    tar -C ${TMP} -xf "${TMP}/go${GO_VERSION}.linux-ppc64le.tar.gz"
    mv "${TMP}/go" /usr/local
  fi
}

__build_travis_worker() {

  export GOPATH="${GO_PATH}"
  export PATH=$PATH:/usr/local/go/bin
  export PATH=$PATH:$(go env GOPATH)/bin

  if [ ! -f "${GO_PATH}/bin/travis-worker" ]; then
    mkdir -p "${GO_PATH}/src/github.com/travis-ci"
    if [ ! -d "${GO_PATH}/src/github.com/travis-ci/worker" ]; then
      git clone https://github.com/travis-ci/worker "${GO_PATH}/src/github.com/travis-ci/worker"
    fi
    cd "${GO_PATH}/src/github.com/travis-ci/worker" || exit

    go get -u github.com/FiloSottile/gvt
    go get -u github.com/alecthomas/gometalinter
    go get -u mvdan.cc/sh/cmd/shfmt
    gometalinter --install
    apt-get update && apt-get -y install shellcheck build-essential

    make deps
    make build
  fi

  if [ -f $GO_PATH/bin/travis-worker ]; then
    cp $GO_PATH/bin/travis-worker /usr/local/bin/travis-worker
  fi
}

__install_docker() {
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  apt-key fingerprint 0EBFCD88
  add-apt-repository "deb [arch=ppc64el] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update -y
  apt-get install -y docker-ce
}

__start_worker_service() {
  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    cp -v "${VARTMP}/travis-worker.service" \
      "${ETCDIR}/systemd/system/travis-worker.service"
    systemctl enable "travis-worker" || true
    systemctl start "travis-worker" || true
  fi
}

__start_docker_service() {
    systemctl enable docker || true
    systemctl start docker || true
}

main "$@"
