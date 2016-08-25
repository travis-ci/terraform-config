.PHONY: hello
hello:
	@echo "Hello there, human.  Would you like to:"
	@echo "  make plan  - plan your demise"
	@echo "  make apply - dance with the devil in the pale moonlight"

.PHONY: apply
apply: ensure-configured
	terraform get
	terraform apply $(PWD)/.terraform.plan

.PHONY: plan
plan: ensure-configured
	terraform get
	terraform plan -module-depth=-1 -out=$(PWD)/.terraform.plan

.PHONY: ensure-configured
ensure-configured:
	test -n "${AWS_REGION}"

.PHONY: config
config:
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/aws-staging.tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	terraform get

.PHONY: prepare-cloud-init
prepare-cloud-init:
	$(RM) -r config
	cp -r $$TRAVIS_KEYCHAIN_DIR/travis-keychain/terraform/aws config
	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/terraform/authorized_keys config

	cat config/aws-workers-org-staging.yml | ruby generate-papertrail-site.rb > config/papertrail-site-org
	cat config/aws-workers-com-staging.yml | ruby generate-papertrail-site.rb > config/papertrail-site-com
