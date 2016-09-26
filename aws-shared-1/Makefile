include $(shell git rev-parse --show-toplevel)/terraform.mk

.PHONY: default
default: hello

CONFIG_FILES := \
	config/bastion-env

.PHONY: .config
.config: $(CONFIG_FILES)

$(CONFIG_FILES):
	mkdir -p config
	trvs generate-config --pro -p aws_bastion -f env $(INFRA)-bastion $(ENV_SHORT) \
		| sed 's/^/export /' >config/bastion-env
