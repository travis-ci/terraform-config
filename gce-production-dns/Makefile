ENV := production-dns
ENV_SHORT := production
INDEX := 0

include $(shell git rev-parse --show-toplevel)/terraform-common.mk

PROD_TF_VERSION := v0.11.2
TERRAFORM := $(HOME)/.cache/travis-terraform-config/terraform-$(PROD_TF_VERSION)

.PHONY: .config
.config:
	@echo no-op

$(TRVS_INFRA_ENV_TFVARS):
	@echo "{}" >$@

$(TRVS_ENV_NAME_TFVARS):
	@echo "{}" >$@
