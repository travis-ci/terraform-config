include $(shell git rev-parse --show-toplevel)/terraform-common.mk

PROD_TF_VERSION := v0.9.11
TERRAFORM := $(HOME)/.cache/travis-terraform-config/terraform-$(PROD_TF_VERSION)

.PHONY: default
default: hello

CONFIG_FILES := \
		config/jupiter-brain-production-org-env \
		config/jupiter-brain-custom-1-env \
		config/jupiter-brain-custom-2-env \
		config/jupiter-brain-custom-4-env \
		config/jupiter-brain-custom-5-env \
		config/jupiter-brain-custom-6-env \
		config/travis-worker-production-com-common \
		config/travis-worker-production-org-common \
		config/vsphere-janitor-production-com \
		config/vsphere-janitor-custom-1 \
		config/vsphere-janitor-custom-2 \
		config/vsphere-janitor-custom-4 \
		config/vsphere-janitor-custom-5 \
		config/vsphere-janitor-custom-6 \
		config/jupiter-brain-production-com-env \
		config/vsphere-monitor \
		config/collectd-vsphere-common \
		config/travis-vm-ssh-key

INDEX ?= $(subst $(INFRA)-$(ENV_SHORT)-,,$(ENV_NAME))

include $(shell git rev-parse --show-toplevel)/trvs.mk


.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).auto.tfvars trvs-collectd-vsphere.auto.tfvars

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/macstadium/travis-vm-ssh-key config/
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain production-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-production-org-env
	trvs generate-config -n -p JUPITER_BRAIN -f env jupiter-brain custom-1-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-custom-1-env
	trvs generate-config -n -p JUPITER_BRAIN -f env jupiter-brain custom-2-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-custom-2-env
	trvs generate-config -n -p JUPITER_BRAIN -f env jupiter-brain custom-4-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-custom-4-env
	trvs generate-config -n -p JUPITER_BRAIN -f env jupiter-brain custom-5-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-custom-5-env
	trvs generate-config --pro -n -p JUPITER_BRAIN -f env jupiter-brain custom-6-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-custom-6-env
	\
	trvs generate-config -n -p TRAVIS_WORKER -f env macstadium-workers production-common \
		| sed 's/^/export /' >config/travis-worker-production-org-common
	trvs generate-config -n --pro -p TRAVIS_WORKER -f env macstadium-workers production-common \
		| sed 's/^/export /' >config/travis-worker-production-com-common
	\
	trvs generate-config --pro -p VSPHERE_JANITOR -f env vsphere-janitor production-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-production-com
	trvs generate-config -n -p VSPHERE_JANITOR -f env vsphere-janitor custom-1-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-custom-1
	trvs generate-config -n -p VSPHERE_JANITOR -f env vsphere-janitor custom-2-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-custom-2
	trvs generate-config -n -p VSPHERE_JANITOR -f env vsphere-janitor custom-4-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-custom-4
	trvs generate-config -n -p VSPHERE_JANITOR -f env vsphere-janitor custom-5-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-custom-5
	trvs generate-config --pro -n -p VSPHERE_JANITOR -f env vsphere-janitor custom-6-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-janitor-custom-6
	trvs generate-config -n -p VSPHERE_MONITOR -f env vsphere-monitor common-$(INDEX) \
		| sed 's/^/export /' >config/vsphere-monitor
	trvs generate-config -n --pro -p JUPITER_BRAIN -f env jupiter-brain production-$(INDEX) \
		| sed 's/^/export /' >config/jupiter-brain-production-com-env
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
