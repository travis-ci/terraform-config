include $(shell git rev-parse --show-toplevel)/terraform-common.mk

PROD_TF_VERSION := v0.9.11
TERRAFORM := $(HOME)/.cache/travis-terraform-config/terraform-$(PROD_TF_VERSION)

.PHONY: default
default: hello

CONFIG_FILES := \
		config/jupiter-brain-staging-org-env \
		config/travis-worker-staging-com-common \
		config/travis-worker-staging-org-common \
		config/vsphere-janitor-staging-com \
		config/jupiter-brain-staging-com-env \
		config/vsphere-monitor \
		config/collectd-vsphere-common \
		config/image-builder \
		config/travis-vm-ssh-key

INDEX ?= $(subst $(INFRA)-$(ENV_SHORT)-,,$(ENV_NAME))

include $(shell git rev-parse --show-toplevel)/trvs.mk


.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).auto.tfvars trvs-collectd-vsphere.auto.tfvars

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/macstadium/travis-vm-ssh-key config/
	trvs generate-config -n -p JUPITER_BRAIN -f env jupiter-brain staging-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-staging-org-env
	trvs generate-config -n -p TRAVIS_WORKER -f env macstadium-workers staging-common \
		| sed 's/^/export /' >config/travis-worker-staging-org-common
	trvs generate-config -n --pro -p TRAVIS_WORKER -f env macstadium-workers staging-common \
		| sed 's/^/export /' >config/travis-worker-staging-com-common
	trvs generate-config -n --env-prefix= -f env macstadium-image-builder image-builder \
		| sed 's/^/export /' >config/image-builder
	\
	trvs generate-config -n --pro -p VSPHERE_JANITOR -f env vsphere-janitor staging-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-staging-com
	trvs generate-config -n -p VSPHERE_MONITOR -f env vsphere-monitor common-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-monitor
	trvs generate-config -n --pro -p JUPITER_BRAIN -f env jupiter-brain staging-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-staging-com-env
	trvs generate-config -n -p COLLECTD_VSPHERE -f env collectd-vsphere common-$(INDEX) \
		| sed 's/^/export /' >config/collectd-vsphere-common

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
