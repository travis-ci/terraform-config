include $(shell git rev-parse --show-toplevel)/terraform.mk

.PHONY: default
default: hello

CONFIG_FILES := \
		config/jupiter-brain-prod-env \
		config/jupiter-brain-staging-env

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).tfvars

$(CONFIG_FILES):
	mkdir -p config
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain production-1 \
		| sed 's/^/export /' >config/jupiter-brain-prod-env
	trvs generate-config -p JUPITER_BRAIN -f env jupiter-brain staging-1 \
		| sed 's/^/export /' >config/jupiter-brain-staging-env
