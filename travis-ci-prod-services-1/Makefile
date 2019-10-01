include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: default
default: hello

INDEX ?= 1
CONTEXT := $(shell terraform output context)

include $(shell git rev-parse --show-toplevel)/trvs.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars

.PHONY: bucket
bucket:
	# One-off: create a bucket for the Terraform state, this assumes ENV_NAME == project name.
	gsutil mb -p $(ENV_NAME) gs://travis-terraform-state

.PHONY: context
context:
	$(TOP)/bin/set-k8s-context ${CONTEXT}
