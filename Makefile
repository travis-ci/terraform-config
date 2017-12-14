SHELLCHECK_URL := https://s3.amazonaws.com/travis-blue-public/binaries/ubuntu/14.04/x86_64/shellcheck-0.4.4.tar.bz2
SHFMT_URL := mvdan.cc/sh/cmd/shfmt

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
deps: .ensure-terraforms .ensure-shellcheck .ensure-shfmt

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
