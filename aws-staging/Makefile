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
	test -n ${AWS_REGION}

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
	mkdir -p config

	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/docker_rsa.key config
	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/aws-workers-org-staging.yml config
	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/aws-workers-com-staging.yml config

	cat $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/aws-workers-org-staging.yml | ruby generate-papertrail-site.rb > config/papertrail-site-org
	cat $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/aws-workers-com-staging.yml | ruby generate-papertrail-site.rb > config/papertrail-site-com

	cp $$TRAVIS_KEYCHAIN_DIR/travis-keychain/aws-workers/ssh-keys.pub config/authorized_keys
