include $(shell git rev-parse --show-toplevel)/terraform.mk

.PHONY: default
default: hello

CONFIG_FILES := \
	config/bastion.env \
	config/gce-workers-$(ENV_SHORT).json \
	config/worker-com.env
	config/worker-org.env

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).tfvars

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/gce/*.json config/
	trvs generate-config -p TRAVIS_WORKER -f env gce-workers $(ENV_TAIL) \
		| sed 's/^/export /' >config/worker-org.env
	trvs generate-config --pro -p TRAVIS_WORKER -f env gce-workers $(ENV_TAIL) \
		| sed 's/^/export /' >config/worker-com.env
	trvs generate-config --pro -p GCE_BASTION -f env gce-bastion $(ENV_SHORT) \
		| sed 's/^/export /' >config/bastion.env
