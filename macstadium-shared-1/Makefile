include $(shell git rev-parse --show-toplevel)/terraform.mk

.PHONY: default
default: hello

CONFIG_FILES := \
		config/jupiter-brain-prod-env \
		config/jupiter-brain-staging-env \
		config/travis-worker-org-staging-1 \
		config/travis-worker-org-staging-2 \
		config/travis-vm-ssh-key

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).tfvars

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/macstadium/travis-vm-ssh-key config/
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain production-1 \
		| sed 's/^/export /' >config/jupiter-brain-prod-org-env
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain staging-1 \
		| sed 's/^/export /' >config/jupiter-brain-staging-org-env
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain custom-1 \
		| sed 's/^/export /' >config/jupiter-brain-custom-1-env
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain custom-2 \
		| sed 's/^/export /' >config/jupiter-brain-custom-2-env
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain custom-3 \
		| sed 's/^/export /' >config/jupiter-brain-custom-3-env
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers staging-1-1 \
		| sed 's/^/export /' >config/travis-worker-org-staging-1
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers staging-1-2 \
		| sed 's/^/export /' >config/travis-worker-org-staging-2
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers production-1-1 \
		| sed 's/^/export /' >config/travis-worker-org-prod-1
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers production-1-2 \
		| sed 's/^/export /' >config/travis-worker-org-prod-2
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers custom-1 \
		| sed 's/^/export /' >config/travis-worker-custom-1
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers custom-2 \
		| sed 's/^/export /' >config/travis-worker-custom-2
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers custom-3 \
		| sed 's/^/export /' >config/travis-worker-custom-3
	trvs generate-config --pro -p VSPHERE_JANITOR -f env vsphere-janitor production-1 \
		| sed 's/^/export /' >config/vsphere-janitor-prod-com
	trvs generate-config --pro -p VSPHERE_JANITOR -f env vsphere-janitor staging-1 \
		| sed 's/^/export /' >config/vsphere-janitor-staging-com
	trvs generate-config -p VSPHERE_JANITOR -f env vsphere-janitor custom-1 \
		| sed 's/^/export /' >config/vsphere-janitor-custom-1
	trvs generate-config -p VSPHERE_JANITOR -f env vsphere-janitor custom-2 \
		| sed 's/^/export /' >config/vsphere-janitor-custom-2
	trvs generate-config -p VSPHERE_JANITOR -f env vsphere-janitor custom-3 \
		| sed 's/^/export /' >config/vsphere-janitor-custom-3
	trvs generate-config --pro -p JUPITER_BRAIN -f env jupiter-brain production-1 \
		| sed 's/^/export /' >config/jupiter-brain-prod-com-env
	trvs generate-config --pro -p JUPITER_BRAIN -f env jupiter-brain staging-1 \
		| sed 's/^/export /' >config/jupiter-brain-staging-com-env
	trvs generate-config --pro -p TRAVIS_WORKER -f env macstadium-workers staging-1-1 \
		| sed 's/^/export /' >config/travis-worker-com-staging-1
	trvs generate-config --pro -p TRAVIS_WORKER -f env macstadium-workers staging-1-2 \
		| sed 's/^/export /' >config/travis-worker-com-staging-2
	trvs generate-config --pro -p TRAVIS_WORKER -f env macstadium-workers production-1-1 \
		| sed 's/^/export /' >config/travis-worker-com-prod-1
	trvs generate-config --pro -p TRAVIS_WORKER -f env macstadium-workers production-1-2 \
		| sed 's/^/export /' >config/travis-worker-com-prod-2
	trvs generate-config -p COLLECTD_VSPHERE -f env collectd-vsphere common-1 \
		| sed 's/^/export /' >config/collectd-vsphere-common-1
