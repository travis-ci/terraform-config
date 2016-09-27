ENV_NAME := $(notdir $(shell cd $(PWD) && pwd))
ENV_SHORT := $(word 2,$(subst -, ,$(ENV_NAME)))
INFRA ?= $(word 1,$(subst -, ,$(ENV_NAME)))
TFVARS := $(PWD)/terraform.tfvars
TFSTATE := $(PWD)/.terraform/terraform.tfstate
TFPLAN := $(PWD)/$(ENV_NAME).tfplan
TFCONF := $(PWD)/.terraform/configured

.PHONY: hello
hello: announce
	@echo "Hello there, human."
	@echo "Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: announce
announce:
	@echo "👋 🎉  This is env=$(ENV_NAME) (short=$(ENV_SHORT) infra=$(INFRA))"

.PHONY: apply
apply: announce .config $(TFVARS) $(TFSTATE)
	terraform apply $(TFPLAN)

.PHONY: plan
plan: announce .config $(TFVARS) $(TFSTATE)
	terraform plan -module-depth=-1 -out=$(TFPLAN)

$(TFCONF): .config $(TFVARS)
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/$(ENV_NAME).tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	touch $@

$(TFSTATE): $(TFCONF)
	terraform get

.PHONY: clean
clean: announce
	$(RM) -r config $(TFVARS) $(TFCONF)

.PHONY: distclean
distclean: clean
	$(RM) -r .terraform/

.PHONY: graph
graph:
	terraform graph -draw-cycles | dot -Tpng > graph.png

$(TFVARS):
	trvs generate-config -f json terraform-config $(subst -,_,$(ENV_NAME)) >$@
