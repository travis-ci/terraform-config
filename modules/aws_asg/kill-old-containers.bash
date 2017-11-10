#!/bin/bash
set -e

main() {
  worker_cid=$(docker inspect travis-worker --format '{{ .Id }}')
  cids=$(docker ps -q --filter before="$worker_cid")

  for cid in $cids; do
    logger "Removing container older than travis-worker: $(docker ps --filter id="$cid" | grep -v CONTAINER)"
    docker kill "$cid"
  done
}

main "$@"
