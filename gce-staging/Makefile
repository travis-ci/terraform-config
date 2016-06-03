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
	mkdir -p config

	trvs generate-config -p travis_worker -f env gce-workers staging | sed 's/^/export /' > config/worker-env-org
	trvs generate-config --pro -p travis_worker -f env gce-workers staging | sed 's/^/export /' > config/worker-env-com

	cat $$TRAVIS_KEYCHAIN_DIR/travis-keychain/gce-accounts/gce-workers-staging.json > config/gce-account.json

	trvs generate-config -p travis_worker -f json gce-workers staging | ruby generate-chef-config.rb > config/chef-org.json
	trvs generate-config --pro -p travis_worker -f json gce-workers staging | ruby generate-chef-config.rb > config/chef-com.json

	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/ssh-keys.pub config/authorized_keys
