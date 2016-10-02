include $(shell git rev-parse --show-toplevel)/terraform-common.mk

$(TFCONF): .config $(TFVARS)
	terraform remote config \
		-backend=local \
		-backend-config="path=$(ENV_NAME).tfstate"
	touch $@

.PHONY: .config
.config:
	@echo no-op

$(TFVARS):
	@echo "{}" >$@
