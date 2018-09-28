#!/bin/bash

org_instances=$(echo production-org-{1..4})
com_instances=$(echo production-com-{1..4})
instances="$org_instances $com_instances"

worker_http_auth() {
  local instance="$1"
  grep HTTP_API_AUTH "/etc/default/travis-worker-${instance}" | cut -d\" -f 2
}

worker_http_port() {
  local instance="$1"
  grep PPROF_PORT "/etc/default/travis-worker-${instance}" | tr -dc '0-9'
}

current_pool_size() {
  local port="$1"
  local auth="$2"
  curl -XPOST "http://$auth@localhost:$port/worker/info" 2>/dev/null | grep 'pool_size' | tr -dc '0-9'
}

desired_pool_size() {
  local instance="$1"
  grep POOL_SIZE "/etc/default/travis-worker-${instance}" | tr -dc '0-9'
}

adjust_pool_size() {
  local inst="$1"
  local port
  local auth
  local cur_pool_size
  local des_pool_size
  port=$(worker_http_port "$inst")
  auth=$(worker_http_auth "$inst")
  echo "Adjusting pool size for travis-worker-$inst"

  cur_pool_size=$(current_pool_size "$port" "$auth")
  des_pool_size=$(desired_pool_size "$inst")
  echo "  Current: $cur_pool_size"
  echo "  Desired: $des_pool_size"

  local diff=$((des_pool_size - cur_pool_size))
  echo "  Diff: $diff"

  if [[ $diff -eq 0 ]]; then
    echo "No changes needed."
  elif [[ $diff -gt 0 ]]; then
    echo "Adding $diff processors to the pool."
    for ((i = 0; i < diff; i++)); do
      curl -XPOST "http://$auth@localhost:$port/worker/pool-incr" 2>/dev/null
      sleep 1
    done
  else
    num=${diff#-}
    echo "Removing $num processors from the pool."
    for ((i = 0; i < num; i++)); do
      curl -XPOST "http://$auth@localhost:$port/worker/pool-decr" 2>/dev/null
      sleep 1
    done
  fi

  echo
}

reset_pool_sizes() {
  for inst in $instances; do
    adjust_pool_size "$inst"
  done
}

case "$1" in
reset-pools)
  reset_pool_sizes
  ;;

*)
  echo $"Usage: $0 {reset-pools|help}"
  exit 1
  ;;
esac
