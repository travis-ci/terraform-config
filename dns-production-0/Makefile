ENV := dns
ENV_SHORT := production
INDEX := 0

include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars

$(TRVS_INFRA_ENV_TFVARS):
	@echo "{}" >$@

$(TRVS_ENV_NAME_TFVARS):
	@echo "{}" >$@

$(ENV_NAME).auto.tfvars:
	$(TOP)/bin/generate-macstadium-nat-ips $@
