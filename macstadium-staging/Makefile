include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: default
default: hello

INDEX ?= 1

include $(shell git rev-parse --show-toplevel)/trvs.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars

.PHONY: context
context:
	$(TOP)/bin/set-k8s-context $(ENV_NAME)
