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
		| sed 's/^/export /' >config/jupiter-brain-prod-env
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain staging-1 \
		| sed 's/^/export /' >config/jupiter-brain-staging-env
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers staging-1-1 \
		| sed 's/^/export /' >config/travis-worker-org-staging-1
	trvs generate-config -p TRAVIS_WORKER -f env macstadium-workers staging-1-2 \
		| sed 's/^/export /' >config/travis-worker-org-staging-2
