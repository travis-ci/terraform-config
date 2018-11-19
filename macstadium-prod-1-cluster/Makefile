include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: default
default: hello

INDEX ?= 1

$(TRVS_INFRA_ENV_TFVARS):
	trvs generate-config -f json -o $@ terraform-config $(INFRA)_$(ENV_SHORT)

$(TRVS_ENV_NAME_TFVARS):
	trvs generate-config -f json -o $@ terraform-config macstadium_prod_1

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars

.PHONY: context
context:
	$(TOP)/bin/set-k8s-context macstadium-prod-1
