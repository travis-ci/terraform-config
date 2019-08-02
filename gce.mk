TOP := $(shell git rev-parse --show-toplevel)

.PHONY: default
default: hello

include $(TOP)/terraform-common.mk
include $(TOP)/trvs.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars
