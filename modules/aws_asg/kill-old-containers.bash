#!/bin/bash

for cid in $(docker ps -q); do
  now=$(date +%s)

  created_at=$(date -d "$(docker inspect --format '{{.Created}}' "$cid")" +%s)
  cutoff=$(echo "$(date +%s)-60*120" | bc)
  ttl=$((created_at - cutoff))
  name="$(docker inspect "$cid" --format '{{ .Name }}')"
  age=$((now - created_at))

  if [ $ttl -lt 0 ]; then
    if [[ "$name" == "/travis-worker" ]]; then
      echo " [OK] travis-worker"
      continue
    fi
    echo "[NOK] $cid: OLD! $(date -d@$age +%H:%M:%S) => $name"
  else
    echo " [OK] $cid: $(date -d@$ttl -u +%H:%M:%S) left => $name"
  fi
done
