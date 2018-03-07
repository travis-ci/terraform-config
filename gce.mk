include $(shell git rev-parse --show-toplevel)/terraform-common.mk

WRITE_CONFIG_OPTS := --write-bastion --write-nat --env-tail $(ENV_TAIL)

.PHONY: default
default: hello

CONFIG_FILES := \
	config/bastion.env \
	config/gce-workers-$(ENV_SHORT).json \
	config/worker-com.env \
	config/worker-org.env \
	$(NATBZ2)

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).auto.tfvars

$(CONFIG_FILES): config/.written config/.gce-keys-written

# Imports network resources from a GCE project that used a single terraform
# graph to manage network resources and workers into a separate network-only
# graph a la "gce-staging-net-1" for "gce-staging-1".  This target is intended
# to be run within a given "net" graph directory such as "gce-production-net-5".
.PHONY: import-net
import-net:
	$(TOP)/bin/gce-import-net \
		--env $(ENV_SHORT) \
		--index $(shell awk -F- '{ print $$NF }' <<<$(ENV_NAME)) \
		--project $(shell $(TOP)/bin/lookup-gce-project $(ENV_NAME)) \
		--terraform $(TERRAFORM)

# Removes state references from a GCE project that has migrated network
# resources to a network-only terraform graph (see `import-net` above). This
# target is intended to be run within a given "non-net" graph directory such as
# "gce-production-5".
.PHONY: export-net
export-net:
	$(TOP)/bin/gce-export-net --terraform $(TERRAFORM)

# Imports worker resources from a GCE project that used a single terraform graph
# to manage network resources and workers into a workers-only graph.  This
# target is intended to be run within a given "non-net" graph directory such as
# "gce-production-5".
.PHONY: import-workers
import-workers:
	$(TOP)/bin/gce-import-workers \
		--count-com $(shell jq -r .worker_instance_count_com <instance-counts.auto.tfvars) \
		--count-org $(shell jq -r .worker_instance_count_org <instance-counts.auto.tfvars) \
		--env $(ENV_SHORT) \
		--index $(shell awk -F- '{ print $$NF }' <<<$(ENV_NAME)) \
		--project $(shell $(TOP)/bin/lookup-gce-project $(ENV_NAME)) \
		--terraform $(TERRAFORM)

# Removes state references from a GCE project that has migrated worker resources
# to a workers-only terraform graph (see `import-workers` above).  This target
# is intended to be run within a given "non-net" graph directory such as
# "gce-production-5".
.PHONY: export-workers
export-workers:
	$(TOP)/bin/gce-export-workers \
		--count-com $(shell jq -r .worker_instance_count_com <instance-counts.auto.tfvars) \
		--count-org $(shell jq -r .worker_instance_count_org <instance-counts.auto.tfvars) \
		--terraform $(TERRAFORM)
