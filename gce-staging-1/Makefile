CONFIG_FILES := \
	config/bastion-env \
	config/gce-workers-staging.json \
	config/vault-consul-env \
	config/worker-env-com \
	config/worker-env-org

TFVARS := $(PWD)/terraform.tfvars
TFSTATE := $(PWD)/.terraform/terraform.tfstate
TFPLAN := $(PWD)/gce-staging.tfplan
TFCONF := $(PWD)/.terraform/configured
TOP := $(shell git rev-parse --show-toplevel)

.PHONY: hello
hello:
	@echo "Hello there, human.  Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: apply
apply: $(CONFIG_FILES) $(TFVARS) $(TFSTATE)
	terraform apply $(TFPLAN)

.PHONY: plan
plan: $(CONFIG_FILES) $(TFVARS) $(TFSTATE)
	terraform plan -module-depth=-1 -out=$(TFPLAN)

$(TFCONF): $(CONFIG_FILES) $(TFVARS)
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/gce-staging.tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	touch $@

$(TFSTATE): $(TFCONF)
	terraform get

.PHONY: clean
clean:
	$(RM) -r config $(TFVARS) $(TFCONF)

.PHONY: distclean
distclean: clean
	$(RM) -r .terraform/

$(CONFIG_FILES):
	mkdir -p config
	cp -v $$TRAVIS_KEYCHAIN_DIR/travis-keychain/gce/*.json config/
	trvs generate-config -p travis_worker -f env gce-workers staging1 \
		| sed 's/^/export /' >config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env gce-workers staging1 \
		| sed 's/^/export /' >config/worker-env-com
	trvs generate-config --pro -p gce_bastion -f env gce-bastion staging \
		| sed 's/^/export /' >config/bastion-env
	trvs generate-config -p gce_vault_consul -f env gce-vault-consul staging \
		>config/vault-consul-env

$(TFVARS):
	trvs generate-config -f json terraform-config gce_staging >$@
