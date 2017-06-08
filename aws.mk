SHELL := bash

TOP := $(shell git rev-parse --show-toplevel)
TRAVIS_BUILD_COM_HOST ?= build.travis-ci.com
TRAVIS_BUILD_ORG_HOST ?= build.travis-ci.org
JOB_BOARD_HOST ?= job-board.travis-ci.com
AMQP_URL_VARNAME ?= AMQP_URL

include $(TOP)/terraform.mk

.PHONY: default
default: hello

CONFIG_FILES := \
	config/travis-build-com.env \
	config/travis-build-org.env \
	config/travis-com.env \
	config/travis-org.env \
	config/worker-com.env \
	config/worker-org.env

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).tfvars

$(CONFIG_FILES):
	$(TOP)/bin/write-aws-config-files \
		"$(INFRA)" \
		"$(ENV_SHORT)" \
		"$(TRAVIS_BUILD_COM_HOST)" \
		"$(TRAVIS_BUILD_ORG_HOST)" \
		"$(JOB_BOARD_HOST)" \
		"$(AMQP_URL_VARNAME)"

.PHONY: diff-docker-images
diff-docker-images:
	@diff -u \
		--label a/docker-images \
		<($(TOP)/bin/show-current-docker-images) \
		--label b/docker-images \
		<($(TOP)/bin/show-proposed-docker-images "$(ENV_NAME).tfvars")
