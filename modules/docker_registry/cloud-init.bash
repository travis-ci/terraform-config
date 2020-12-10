#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  [[ "${QUIET}" ]] || set -o xtrace

  : "${DEV:=/dev}"
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${VARLIBDIR:=/var/lib}"
  : "${VARLOGDIR:=/var/log}"
  : "${VARTMP:=/var/tmp}"

  export DEBIAN_FRONTEND=noninteractive
  chown nobody:nogroup "${VARTMP}"
  chmod 0777 "${VARTMP}"

  for substep in \
    monitoring_agent \
    restore_registry \
    docker_registry \
    registry_backup; do
    logger running setup substep="${substep}"
    "__setup_${substep}"
  done
}

__wait_for_docker() {
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    systemctl start docker &>/dev/null || true
    sleep 10
    let i+=10
  done
}

__setup_monitoring_agent() {

  curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
  bash add-monitoring-agent-repo.sh
  apt update -yqq
  apt install stackdriver-agent -y

}

__setup_restore_registry() {

  gcloud auth activate-service-account --key-file=/etc/google/auth/application_default_credentials.json
  PROJECT_ID=$(gcloud config get-value project)
  BUCKET=${PROJECT_ID}-docker-registry
  mkdir -p /var/lib/registry
  touch /var/lib/registry/gsutil.lock
  gsutil -m rsync -r gs://${BUCKET}/ /var/lib/registry/ >/dev/null 2>&1 && rm -f /var/lib/registry/gsutil.lock &

}

__setup_docker_registry() {

  apt update -yqq
  apt install docker.io -y
  docker pull gcr.io/travis-ci-prod-oss-4/registry:v2.7.0-167-g551158e6
  docker tag gcr.io/travis-ci-prod-oss-4/registry:v2.7.0-167-g551158e6 registry:2
  docker run -d -p 443:443 --restart=always --name registry --env-file /etc/docker/registry/env -v /etc/docker/registry/config.yml:/etc/docker/registry/config.yml -v /etc/ssl/docker:/etc/ssl/docker -v /var/lib/registry:/var/lib/registry registry:2

}

__setup_registry_backup() {

  tee /usr/local/bin/docker-registry-backup.sh <<-'EOF'
#!/bin/bash

set -o errtrace

exec 1>/var/log/docker-registry-backup.log 2>&1

. /etc/profile.d/apps-bin-path.sh

if [[ -f /var/lib/registry/gsutil.lock ]]; then
  echo "Lock file present"; exit 1;
fi

gcloud auth activate-service-account --key-file=/etc/google/auth/application_default_credentials.json
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
PROJECT_ID=$(gcloud config get-value project)
BUCKET=${PROJECT_ID}-docker-registry
echo $INSTANCE_NAME > /var/lib/registry/INSTANCE_NAME

gsutil cp gs://${BUCKET}/INSTANCE_NAME /tmp/ || true
DOCKER_REGISTRY_INSTANCE_NAME=$(cat /tmp/INSTANCE_NAME)

if [[ -z "$DOCKER_REGISTRY_INSTANCE_NAME" ]]; then
  gsutil cp /var/lib/registry/INSTANCE_NAME gs://${BUCKET}/
  DOCKER_REGISTRY_INSTANCE_NAME=${INSTANCE_NAME}
fi

INSTANCES=$(gcloud compute instances list) || { echo "Something went wrong"; exit 1; }
echo ${INSTANCES} | grep -q ${DOCKER_REGISTRY_INSTANCE_NAME}
status=$?

if [[ $status -eq 1 ]]; then
  gsutil cp /var/lib/registry/INSTANCE_NAME gs://${BUCKET}/
  status=0
  DOCKER_REGISTRY_INSTANCE_NAME=${INSTANCE_NAME}
fi

if [[ $DOCKER_REGISTRY_INSTANCE_NAME == $INSTANCE_NAME ]] && [[ $status -eq 0 ]]; then
  gsutil mb gs://${BUCKET} || true
  gsutil cp /var/lib/registry/INSTANCE_NAME gs://${BUCKET}/
  gsutil -m rsync -r -d /var/lib/registry/ gs://${BUCKET}/
fi
EOF
  chmod +x /usr/local/bin/docker-registry-backup.sh
  rand=$(( RANDOM % 60 ))
  ( crontab -l | echo "${rand} */4 * * * /usr/local/bin/docker-registry-backup.sh >/dev/null 2>&1" ) | crontab -

}

main "${@}"
