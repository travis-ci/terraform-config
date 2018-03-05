include $(shell git rev-parse --show-toplevel)/terraform.mk

.PHONY: default
default: hello

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars
