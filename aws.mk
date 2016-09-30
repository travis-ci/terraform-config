SHELL := bash

TOP := $(shell git rev-parse --show-toplevel)
TRAVIS_BUILD_COM_HOST ?= build.travis-ci.com
TRAVIS_BUILD_ORG_HOST ?= build.travis-ci.org
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
.config: $(CONFIG_FILES)

$(CONFIG_FILES):
	mkdir -p config
	trvs generate-config --pro -p travis_worker -f env $(INFRA)-workers $(ENV_SHORT) \
		| sed 's/^/export /' >config/worker-com.env
	trvs generate-config -p travis_worker -f env $(INFRA)-workers $(ENV_SHORT) \
		| sed 's/^/export /' >config/worker-org.env
	$(TOP)/bin/heroku-dump-shell-config travis-$(ENV_SHORT) >config/travis-org.env
	$(TOP)/bin/heroku-dump-shell-config travis-build-$(ENV_SHORT) >config/travis-build-org.env
	$(TOP)/bin/heroku-dump-shell-config travis-pro-$(ENV_SHORT) >config/travis-com.env
	$(TOP)/bin/heroku-dump-shell-config travis-pro-build-$(ENV_SHORT) >config/travis-build-com.env
	source config/travis-build-com.env && source config/travis-com.env && \
		echo 'export TRAVIS_WORKER_BUILD_API_URI=https://'"$${API_TOKEN}"'@$(TRAVIS_BUILD_COM_HOST)/script' \
			>config/worker-com-local.env && \
		echo 'export TRAVIS_WORKER_AMQP_URI='$${$(AMQP_URL_VARNAME)} >>config/worker-com-local.env && \
		$(TOP)/bin/env-url-to-parts $(AMQP_URL_VARNAME) config/ com
	source config/travis-build-org.env && source config/travis-org.env && \
		echo 'export TRAVIS_WORKER_BUILD_API_URI=https://'"$${API_TOKEN}"'@$(TRAVIS_BUILD_ORG_HOST)/script' \
			>config/worker-org-local.env && \
		echo 'export TRAVIS_WORKER_AMQP_URI='$${$(AMQP_URL_VARNAME)} >>config/worker-org-local.env && \
		$(TOP)/bin/env-url-to-parts $(AMQP_URL_VARNAME) config/ org
