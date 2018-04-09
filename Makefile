SHELLCHECK_URL := https://s3.amazonaws.com/travis-blue-public/binaries/ubuntu/14.04/x86_64/shellcheck-0.4.4.tar.bz2
SHFMT_URL := mvdan.cc/sh/cmd/shfmt
TFPLAN2JSON_URL := github.com/travis-ci/tfplan2json

SHELL := bash

GIT := git
GO := go
CURL := curl
TAR := tar

.PHONY: test
test:
	./runtests --env .example.env

include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: assert-clean
assert-clean:
	$(GIT) diff --exit-code
	$(GIT) diff --cached --exit-code

.PHONY: deps
deps: .ensure-git .ensure-terraforms .ensure-shellcheck .ensure-shfmt .ensure-tfplan2json

.PHONY: .ensure-terraforms
.ensure-terraforms:
	$(GIT) ls-files '*/Makefile' | \
		xargs -n 1 $(MAKE) .echo-tf-version -f 2>/dev/null | \
		grep -v make | \
		sort | \
		uniq | while read -r tf_version; do \
			./bin/ensure-terraform $${tf_version}; \
		done

.PHONY: .ensure-shellcheck
.ensure-shellcheck:
	if [[ ! -x "$(HOME)/bin/shellcheck" ]]; then \
		$(CURL) -sSL "$(SHELLCHECK_URL)" | $(TAR) -C "$(HOME)/bin" -xjf -; \
	fi

.PHONY: .ensure-shfmt
.ensure-shfmt:
	$(GO) get -u "$(SHFMT_URL)"

.PHONY: .ensure-tfplan2json
.ensure-tfplan2json:
	$(GO) get -u "$(TFPLAN2JSON_URL)"

.PHONY: .ensure-git
.ensure-git:
	if [[ "$$(git rev-parse --abbrev-ref HEAD)" != "master" ]]; then \
		echo "$$(tput setaf 1)WARN: You are about to deploy from a branch that is not master!$$(tput sgr 0)" ;\
		echo "If you are $$(tput setaf 1)SUPER DUPER SURE$$(tput sgr 0) you wish to do this, type yes:" ;\
		read answer; \
		if [[ "$$answer" == "yes" ]]; then \
			echo "Okay have fun!"; \
		else \
			echo "That's a good call too, better luck next time." ; \
			exit 1; \
		fi ;\
	fi
