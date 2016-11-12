#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${POST_SHUTDOWN_SLEEP:=300}"

  if [[ -f "${RUNDIR}/implode" ]]; then
    local reason
    reason="$(cat "${RUNDIR}/implode" 2>/dev/null)"
    : "${reason:=not sure why}"
    echo "refusing to start travis-worker; instance imploding because ${reason}"
    echo "${reason}" | tee /var/tmp/travis-run.d/implode.confirm
    sleep "${POST_SHUTDOWN_SLEEP}"
    exit 1
  fi

  if [[ ! -f "${RUNDIR}/instance-token" ]]; then
    curl \
      -f \
      -s \
      -o "${RUNDIR}/instance-token" \
      -H 'Accept: text/plain' \
      -H "Authorization: token $CYCLIST_AUTH_TOKEN" \
      "$CYCLIST_URL/tokens/$(cat "${RUNDIR}/instance-id")"
  fi

  set -o xtrace

  local i=0
  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    sleep 10
    let i+=10
  done

  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_ANDROID" travis:android
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_DEFAULT" travis:default
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_ERLANG" travis:erlang
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_ERLANG" travis:elixir
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_GO" travis:go
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_HASKELL" travis:haskell
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_JVM" travis:jvm
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_JVM" travis:clojure
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_JVM" travis:groovy
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_JVM" travis:java
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_JVM" travis:scala
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_NODE_JS" travis:node-js
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_NODE_JS" travis:node_js
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_PERL" travis:perl
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_PHP" travis:php
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_PYTHON" travis:python
  __docker_pull_tag "$TRAVIS_WORKER_DOCKER_IMAGE_RUBY" travis:ruby
}

__docker_pull_tag() {
  local image="$1"
  local tag="$2"

  [[ "$image" ]] || {
    echo 'Missing image name'
    return 1
  }

  docker pull "$image"
  docker tag "$image" "$tag"
}

main "$@"
