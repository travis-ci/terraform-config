ENV_NAME := $(notdir $(shell cd $(PWD) && pwd))
ENV_SHORT ?= $(word 2,$(subst -, ,$(ENV_NAME)))
INFRA ?= $(word 1,$(subst -, ,$(ENV_NAME)))
ENV_TAIL ?= $(subst $(INFRA)-,,$(ENV_NAME))
TFVARS := $(PWD)/terraform.tfvars
TFSTATE := $(PWD)/.terraform/terraform.tfstate
TFPLAN := $(PWD)/$(ENV_NAME).tfplan
TOP := $(shell git rev-parse --show-toplevel)

.PHONY: hello
hello: announce
	@echo "Hello there, human."
	@echo "Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: checkversion
checkversion:
	ruby $(TOP)/check_version.rb

.PHONY: announce
announce: checkversion
	@echo "👋 🎉  This is env=$(ENV_NAME) (short=$(ENV_SHORT) infra=$(INFRA) tail=$(ENV_TAIL))"

.PHONY: apply
apply: announce .config $(TFVARS) $(TFSTATE)
	terraform apply $(TFPLAN)

.PHONY: plan
plan: announce .config $(TFVARS) $(TFSTATE)
	terraform plan \
		-var-file=$(ENV_NAME).tfvars \
		-var-file=$(TFVARS) \
		-module-depth=-1 \
		-out=$(TFPLAN)

.PHONY: destroy
destroy: announce .config $(TFVARS) $(TFSTATE)
	terraform plan \
		-var-file=$(ENV_NAME).tfvars \
		-var-file=$(TFVARS) \
		-module-depth=-1 \
		-destroy \
		-out=$(TFPLAN)

$(TFSTATE):
	terraform init

.PHONY: clean
clean: announce
	$(RM) -r config $(TFVARS) $(ENV_NAME).tfvars

.PHONY: distclean
distclean: clean
	$(RM) -r .terraform/

.PHONY: graph
graph:
	terraform graph -draw-cycles | dot -Tpng > graph.png

$(ENV_NAME).tfvars:
	$(TOP)/bin/generate-tfvars $@

.PHONY: list
list:
	 @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

.PHONY: check
check:
	$(TOP)/bin/pre-flight-checks $@
