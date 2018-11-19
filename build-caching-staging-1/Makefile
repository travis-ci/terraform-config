AMQP_URL_VARNAME := CLOUDAMQP_URL
ENV_SHORT := staging
INFRA := build-caching
TOP := $(shell git rev-parse --show-toplevel)

include $(TOP)/terraform-common.mk
include $(TOP)/trvs.mk

.config: $(ENV_NAME).auto.tfvars $(TRVS_INFRA_ENV_TFVARS)

$(TRVS_INFRA_ENV_TFVARS):
	trvs generate-config -f json -a terraform-config -e terraform_common -o $@
