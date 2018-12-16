AMQP_URL_COM_VARNAME := CLOUDAMQP_URL
AMQP_URL_ORG_VARNAME := CLOUDAMQP_GRAY_URL
ENV_SHORT := production
INFRA := build-caching
TOP := $(shell git rev-parse --show-toplevel)

include $(TOP)/terraform-common.mk
include $(TOP)/trvs.mk

.config: $(ENV_NAME).auto.tfvars $(TRVS_INFRA_ENV_TFVARS)

$(TRVS_INFRA_ENV_TFVARS):
	trvs generate-config -f json -a terraform-config -e terraform_common -o $@

plan:
	@echo DISABLED OK

apply:
	@echo NO REALLY DONT DO THIS
