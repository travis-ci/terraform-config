TOP := $(shell git rev-parse --show-toplevel)

include $(TOP)/terraform.mk

.PHONY: default
default: hello

AWS_ROUTE_TABLE_PUBLIC := aws_route_table_public.tf
CONFIG_FILES := \
	config/bastion-env

.PHONY: .config
.config: $(CONFIG_FILES) $(AWS_ROUTE_TABLE_PUBLIC)

.PHONY: clean
clean: announce
	$(RM) -r config $(TFVARS) $(TFCONF) $(AWS_ROUTE_TABLE_PUBLIC)

$(CONFIG_FILES):
	mkdir -p config
	trvs generate-config --pro -p aws_bastion -f env $(INFRA)-bastion $(ENV_SHORT) \
		| sed 's/^/export /' >config/bastion-env

$(AWS_ROUTE_TABLE_PUBLIC):
	$(TOP)/bin/generate-aws-route-table-public >$@
