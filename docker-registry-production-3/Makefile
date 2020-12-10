ENV_SHORT := production
INFRA := docker-registry
VAULT_SOURCE_PATH := docker-registry
VAULT_SECRET_KEY := docker-registry
VAULT_GCP_SECRET_KEY := docker-gcp-registry-prod-3
TOP := $(shell git rev-parse --show-toplevel)

ifeq ($(VAULT_ADDR),)
  $(error VAULT_ADDR is not set)
endif

ifeq ($(VAULT_TOKEN),)
  $(error VAULT_TOKEN is not set)
endif

include $(TOP)/terraform-common.mk
include $(TOP)/trvs.mk

# Use terraform v0.12.29
PROD_TF_VERSION := v0.12.29
TERRAFORM := $(TF_INSTALLATION_PREFIX)/terraform-$(PROD_TF_VERSION)

export PROD_TF_VERSION
export TERRAFORM

.config: $(ENV_NAME).auto.tfvars $(TRVS_INFRA_ENV_TFVARS)

$(ENV_NAME).auto.tfvars:
	@echo "" >$@

$(TRVS_INFRA_ENV_TFVARS):
	vault kv get -format=json -field=data ${VAULT_SOURCE_PATH}/${VAULT_SECRET_KEY} > ${VAULT_SECRET_KEY}.auto.tfvars.json
	vault kv get -format=json -field=data ${VAULT_SOURCE_PATH}/${VAULT_GCP_SECRET_KEY} > ${VAULT_GCP_SECRET_KEY}.auto.tfvars.json

$(TRVS_ENV_NAME_TFVARS):
	@echo "" >$@
