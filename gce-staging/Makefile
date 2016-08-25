.PHONY: apply
apply: ensure-configured
	terraform get
	terraform apply

.PHONY: plan
plan: ensure-configured
	terraform get
	terraform plan

.PHONY: ensure-configured
ensure-configured:
	test -n ${GOOGLE_REGION}

.PHONY: config
config:
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/gce-staging.tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	terraform get

.PHONY: prepare-cloud-init
prepare-cloud-init:
	$(RM) -r config
	cp -r $$TRAVIS_KEYCHAIN_DIR/travis-keychain/terraform/gce config
	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/terraform/authorized_keys config

	trvs generate-config -p travis_worker -f env gce-workers staging1 | sed 's/^/export /' > config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env gce-workers staging1 | sed 's/^/export /' > config/worker-env-com

	trvs generate-config -p travis_worker -f json gce-workers staging1 | ruby generate-chef-config.rb > config/chef-org.json
	trvs generate-config --pro -p travis_worker -f json gce-workers staging1 | ruby generate-chef-config.rb > config/chef-com.json
