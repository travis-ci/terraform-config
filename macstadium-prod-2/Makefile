include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: default
default: hello

INDEX ?= 2

include $(shell git rev-parse --show-toplevel)/trvs.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars
