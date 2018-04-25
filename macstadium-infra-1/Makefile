include $(shell git rev-parse --show-toplevel)/terraform-common.mk

PROD_TF_VERSION := v0.11.6
TERRAFORM := $(HOME)/.cache/travis-terraform-config/terraform-$(PROD_TF_VERSION)

.PHONY: default
default: hello

CONFIG_FILES := ""

INDEX ?= $(subst $(INFRA)-$(ENV_SHORT)-,,$(ENV_NAME))

include $(shell git rev-parse --show-toplevel)/trvs.mk


.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).auto.tfvars trvs-collectd-vsphere.auto.tfvars

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/macstadium/travis-vm-ssh-key config/

.PHONY: plan
plan: announce .config $(TRVS_TFVARS) $(TFSTATE)
	$(TERRAFORM) plan -module-depth=-1 \
		-var-file=$(ENV_NAME).auto.tfvars \
		-var-file=trvs-collectd-vsphere.auto.tfvars \
		-var-file=trvs-$(ENV_NAME).auto.tfvars \
		-var-file=trvs-$(INFRA)-$(ENV_SHORT).auto.tfvars \
		-out=$(TFPLAN)

$(ENV_NAME).auto.tfvars:
	$(TOP)/bin/generate-tfvars $@

trvs-collectd-vsphere.auto.tfvars:
	trvs generate-config -f json collectd-vsphere common-$(INDEX) -o $@
