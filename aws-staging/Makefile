CONFIG_FILES := \
	config/worker-env-com \
	config/worker-env-org \
	config/chef-org.json \
	config/chef-com.json

TFVARS := $(PWD)/terraform.tfvars
TFPLAN := $(PWD)/aws-staging.tfplan
TOP := $(shell git rev-parse --show-toplevel)

.PHONY: hello
hello:
	@echo "Hello there, human.  Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: apply
apply: $(CONFIG_FILES) $(TFVARS)
	terraform get
	terraform apply $(TFPLAN)

.PHONY: plan
plan: $(CONFIG_FILES) $(TFVARS)
	terraform get
	terraform plan -module-depth=-1 -out=$(TFPLAN)

.PHONY: config
config: $(CONFIG_FILES) $(TFVARS)
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/aws-staging.tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	terraform get

.PHONY: clean
clean:
	$(RM) -r config $(TFVARS)

$(CONFIG_FILES):
	mkdir -p config
	trvs generate-config -p travis_worker -f env aws-workers staging \
		| sed 's/^/export /' >config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env aws-workers staging \
		| sed 's/^/export /' >config/worker-env-com
	trvs generate-config -p travis_worker -f json aws-workers staging \
		| $(TOP)/bin/generate-chef-config >config/chef-org.json
	trvs generate-config --pro -p travis_worker -f json aws-workers staging \
		| $(TOP)/bin/generate-chef-config >config/chef-com.json

$(TFVARS):
	trvs generate-config -f json terraform-config aws_staging >$@
