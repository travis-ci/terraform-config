include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: default
default: hello

INDEX ?= 1

include $(shell git rev-parse --show-toplevel)/trvs.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars

.PHONY: context
context:
	terraform taint -module=kubernetes_cluster null_resource.kubectl_context
	terraform apply -target module.kubernetes_cluster.null_resource.kubectl_context

.PHONY: bucket
bucket:
	# One-off: create a bucket for the Terraform state, this assumes ENV_NAME == project name.
	gsutil mb -p $(ENV_NAME) gs://travis-terraform-state
