AMQP_URL_VARNAME := RABBITMQ_BIGWIG_RX_URL
ENV_SHORT := staging
JOB_BOARD_HOST := job-board-staging.travis-ci.com
TRAVIS_BUILD_COM_HOST := build-staging.travis-ci.com
TRAVIS_BUILD_ORG_HOST := build-staging.travis-ci.org

include $(shell git rev-parse --show-toplevel)/gce.mk

TERRAFORM := $(HOME)/.cache/travis-terraform-config/terraform-$(PROD_TF_VERSION)
