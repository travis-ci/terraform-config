include ../terraform.mk

.PHONY: default
default: hello

CONFIG_FILES := \
	config/bastion-env \
	config/gce-workers-$(ENV_SHORT).json \
	config/vault-consul-env \
	config/worker-env-com \
	config/worker-env-org

.PHONY: .config
.config: $(CONFIG_FILES)

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/gce/*.json config/
	trvs generate-config -p travis_worker -f env gce-workers $(ENV_SHORT) \
		| sed 's/^/export /' >config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env gce-workers $(ENV_SHORT) \
		| sed 's/^/export /' >config/worker-env-com
	trvs generate-config --pro -p gce_bastion -f env gce-bastion $(ENV_SHORT) \
		| sed 's/^/export /' >config/bastion-env
	trvs generate-config -p gce_vault_consul -f env gce-vault-consul $(ENV_SHORT) \
		>config/vault-consul-env
