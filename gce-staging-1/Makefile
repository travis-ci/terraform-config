ENV_NAME := $(notdir $(shell cd $(PWD) && pwd))
ENV_SHORT := $(word 2,$(subst -, ,$(ENV_NAME)))
TFVARS := $(PWD)/terraform.tfvars
TFSTATE := $(PWD)/.terraform/terraform.tfstate
TFPLAN := $(PWD)/$(ENV_NAME).tfplan
TFCONF := $(PWD)/.terraform/configured

CONFIG_FILES := \
	config/bastion-env \
	config/gce-workers-$(ENV_SHORT).json \
	config/vault-consul-env \
	config/worker-env-com \
	config/worker-env-org

.PHONY: hello
hello:
	@echo "Hello there, human.  This is env=$(ENV_NAME) (short=$(ENV_SHORT))"
	@echo "Would you like to:"
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
	    -backend-config=key=terraform-config/$(ENV_NAME).tfstate \
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
	trvs generate-config -p travis_worker -f env gce-workers $(ENV_SHORT) \
		| sed 's/^/export /' >config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env gce-workers $(ENV_SHORT) \
		| sed 's/^/export /' >config/worker-env-com
	trvs generate-config --pro -p gce_bastion -f env gce-bastion $(ENV_SHORT) \
		| sed 's/^/export /' >config/bastion-env
	trvs generate-config -p gce_vault_consul -f env gce-vault-consul $(ENV_SHORT) \
		>config/vault-consul-env

$(TFVARS):
	trvs generate-config -f json terraform-config $(subst -,_,$(ENV_NAME)) >$@
