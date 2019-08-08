SHELL := bash
ENV_NAME := $(notdir $(shell cd $(PWD) && pwd))
ENV_SHORT ?= $(word 2,$(subst -, ,$(ENV_NAME)))
INFRA ?= $(word 1,$(subst -, ,$(ENV_NAME)))
ENV_TAIL ?= $(subst $(INFRA)-,,$(ENV_NAME))
TRVS_INFRA_ENV_TFVARS := $(PWD)/trvs-$(INFRA)-$(ENV_SHORT).auto.tfvars
TRVS_ENV_NAME_TFVARS := $(PWD)/trvs-$(ENV_NAME).auto.tfvars
TRVS_TFVARS := $(TRVS_INFRA_ENV_TFVARS) $(TRVS_ENV_NAME_TFVARS)
TFSTATE := $(PWD)/.terraform/terraform.tfstate
TFPLAN := $(PWD)/$(ENV_NAME).tfplan
TRAVIS_BUILD_COM_HOST ?= build.travis-ci.com
TRAVIS_BUILD_ORG_HOST ?= build.travis-ci.org
JOB_BOARD_HOST ?= job-board.travis-ci.com
AMQP_URL_COM_VARNAME ?= AMQP_URL
AMQP_URL_ORG_VARNAME ?= AMQP_URL
TOP := $(shell git rev-parse --show-toplevel)
NATBZ2 := $(TOP)/assets/nat.tar.bz2

PROD_TF_VERSION := v0.11.13
TERRAFORM := $(TF_INSTALLATION_PREFIX)/terraform-$(PROD_TF_VERSION)

export PROD_TF_VERSION
export TERRAFORM

.PHONY: hello
hello: announce
	@echo "Hello there, human."
	@echo "Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: .assert-ruby
.assert-ruby:
	@ruby -e "fail 'Ruby >= 2.4 required' unless RUBY_VERSION >= '2.4'"

.PHONY: .echo-tf-version
.echo-tf-version:
	@echo $(PROD_TF_VERSION)

.PHONY: .echo-tf
.echo-tf:
	@echo $(TERRAFORM)

.PHONY: .assert-tf-version
.assert-tf-version:
	@TF_INSTALL_MISSING=0 $(TOP)/bin/ensure-terraform $(PROD_TF_VERSION)

.PHONY: announce
announce: .assert-ruby .assert-tf-version
	@echo "👋 🎉  This is env=$(ENV_NAME) (short=$(ENV_SHORT) infra=$(INFRA) tail=$(ENV_TAIL))"

.PHONY: apply
apply: announce .ensure-git .config $(TRVS_TFVARS) $(TFSTATE)
	$(TERRAFORM) apply $(TFPLAN)
	$(TOP)/bin/post-flight $(TOP)

.PHONY: init
init: announce
	$(TERRAFORM) init

.PHONY: show
show: announce
	$(TERRAFORM) show

.PHONY: console
console: announce
	$(TERRAFORM) console

.PHONY: plan
plan: announce .config $(TRVS_TFVARS) $(TFSTATE)
	$(TERRAFORM) plan -module-depth=-1 -out=$(TFPLAN)

.PHONY: planbeep
planbeep: announce .config $(TRVS_TFVARS) $(TFSTATE)
	$(TERRAFORM) plan -module-depth=-1 -out=$(TFPLAN) | ruby -ne 'puts $$_.gsub(/(metadata.user-data: *")(.*)(".*)/, "\\1beep\\3")'

.PHONY: plandiff
plandiff: $(TFPLAN)
	$(TOP)/bin/tfplandiff $^

.PHONY: destroy
destroy: announce .config $(TRVS_TFVARS) $(TFSTATE)
	$(TERRAFORM) plan -module-depth=-1 -destroy -out=$(TFPLAN)
	$(TOP)/bin/post-flight $(TOP)

.PHONY: tar
tar:
UNAME := $(shell uname -s | tr '[A-Z]' '[a-z]')
ifeq ($(UNAME),darwin)
  TAR := gtar
else
  ifeq ($(UNAME),linux)
    TAR := tar
  else
    $(error Operating system $(UNAME) is not yet supported)
  endif
endif
ifeq (,$(shell which $(TAR)))
  $(info Please ensure GNU tar is installed and is available as $(TAR), e.g. with `brew install gnu-tar`)
  $(error No valid tar found.)
endif
TAR := LC_ALL=C $(TAR) \
      --mtime='1970-01-01 00:00:00 +0000' \
      --mode='go=rX,u+rw,a-s' \
      --owner=0 \
      --group=0 \
      --numeric-owner \
      --sort=name \
      -cj

$(NATBZ2): tar $(wildcard $(TOP)/assets/nat/**/*)
	$(TAR) -C $(TOP)/assets -f $(NATBZ2) nat

$(TFSTATE):
	$(TERRAFORM) init

.PHONY: clean
clean: announce
	$(RM) -r config $(TRVS_TFVARS) $(ENV_NAME).auto.tfvars

.PHONY: distclean
distclean: clean
	$(RM) -r .terraform/

.PHONY: graph
graph:
	$(TERRAFORM) graph -draw-cycles | dot -Tpng > graph.png

$(ENV_NAME).auto.tfvars:
	$(TOP)/bin/generate-tfvars $@

.PHONY: list
list:
	 @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

.PHONY: check
check:
	$(TOP)/bin/pre-flight-checks $@

.PHONY: .ensure-git
.ensure-git:
	@if [[ "$$(git rev-parse --abbrev-ref HEAD)" != "master" ]]; then \
		echo "$$(tput setaf 1)WARN: You are about to deploy from a branch that is not master!$$(tput sgr 0)"; \
		echo -n "If you are $$(tput setaf 1)SUPER DUPER SURE$$(tput sgr 0) you wish to do this, type yes: "; \
		read -r answer; \
		if [[ "$$answer" == "yes" ]]; then \
			echo "Okay have fun!"; \
		else \
			echo "That's a good call too, better luck next time."; \
			exit 1; \
		fi; \
	fi

config/.written:
	$(TOP)/bin/write-config-files \
		--infra "$(INFRA)" \
		--env "$(ENV_SHORT)" \
		--build-com-host "$(TRAVIS_BUILD_COM_HOST)" \
		--build-org-host "$(TRAVIS_BUILD_ORG_HOST)" \
		--job-board-host "$(JOB_BOARD_HOST)" \
		--amqp-url-org-varname "$(AMQP_URL_ORG_VARNAME)" $(WRITE_CONFIG_OPTS) \
		--amqp-url-com-varname "$(AMQP_URL_COM_VARNAME)" $(WRITE_CONFIG_OPTS)

config/.gce-keys-written:
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/gce/*.json config/
	date -u >$@
