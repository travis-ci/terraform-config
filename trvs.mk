# Define default rules for building TRVS_INFRA_ENV_TFVARS and
# TRVS_ENV_NAME_TFVARS, which is intended to be used by projects that do not
# need custom behavior by including this file via:
#
#     include $(shell git rev-parse --show-toplevel)/trvs.mk
#
$(TRVS_INFRA_ENV_TFVARS):
	trvs generate-config -f json -o $@ terraform-config $(INFRA)_$(ENV_SHORT)

$(TRVS_ENV_NAME_TFVARS):
	trvs generate-config -f json -o $@ terraform-config $(subst -,_,$(ENV_NAME))
