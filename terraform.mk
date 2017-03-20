include $(shell git rev-parse --show-toplevel)/terraform-common.mk

$(TFVARS):
	trvs generate-config -f json terraform-config $(subst -,_,$(ENV_NAME)) >$@
