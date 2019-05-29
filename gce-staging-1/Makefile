TRAVIS_BUILD_COM_HOST := build-staging.travis-ci.com
TRAVIS_BUILD_ORG_HOST := build-staging.travis-ci.org
JOB_BOARD_HOST := job-board-staging.travis-ci.com
AMQP_URL_COM_VARNAME := CLOUDAMQP_URL
AMQP_URL_ORG_VARNAME := CLOUDAMQP_GRAY_URL
GKE_CLUSTER_NAME ?= gce-staging-1

include $(shell git rev-parse --show-toplevel)/gce.mk

.PHONY: context
context:
	gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --zone us-central1-a --project travis-staging-1
	kubectl config set-context gke_travis-staging-1_us-central1-a_${GKE_CLUSTER_NAME} --namespace=gce-staging-1
