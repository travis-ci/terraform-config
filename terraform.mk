include $(shell git rev-parse --show-toplevel)/terraform-common.mk

$(TFCONF): .config $(TFVARS)
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/$(ENV_NAME).tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	touch $@

$(TFVARS):
	trvs generate-config -f json terraform-config $(subst -,_,$(ENV_NAME)) >$@
