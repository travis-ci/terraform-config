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
