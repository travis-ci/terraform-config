CONFIG_FILES := \
	config/worker-env-com \
	config/worker-env-org \
	config/bastion-env \
	config/chef-org.json \
	config/chef-com.json \
	config/gce-workers-staging.json

TFPLAN := $(PWD)/gce-staging.tfplan
TOP := $(shell git rev-parse --show-top-level)

.PHONY: hello
hello:
	@echo "Hello there, human.  Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: apply
apply: $(CONFIG_FILES)
	terraform get
	terraform apply $(TFPLAN)

.PHONY: plan
plan: $(CONFIG_FILES)
	terraform get
	terraform plan -module-depth=-1 -out=$(TFPLAN)

.PHONY: config
config:
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/gce-staging.tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	terraform get

.PHONY: clean
clean:
	$(RM) -r config

$(CONFIG_FILES):
	cp -r $$TRAVIS_KEYCHAIN_DIR/travis-keychain/terraform/gce config
	trvs generate-config -p travis_worker -f env gce-workers staging1 \
		| sed 's/^/export /' >config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env gce-workers staging1 \
		| sed 's/^/export /' >config/worker-env-com
	trvs generate-config --pro -p gce_bastion -f env gce-bastion staging \
		| sed 's/^/export /' >config/bastion-env
	trvs generate-config -p travis_worker -f json gce-workers staging1 \
		| $(TOP)/bin/generate-chef-config >config/chef-org.json
	trvs generate-config --pro -p travis_worker -f json gce-workers staging1 \
		| $(TOP)/bin/generate-chef-config >config/chef-com.json
