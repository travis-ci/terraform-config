include $(shell git rev-parse --show-toplevel)/terraform-common.mk

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars

$(TRVS_INFRA_ENV_TFVARS):
	trvs generate-config -f json -a terraform-config -e terraform_common -o $@

$(TRVS_ENV_NAME_TFVARS):
	@echo "{}" >$@

$(ENV_NAME).auto.tfvars:
	@echo "{}" >$@
