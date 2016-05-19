.PHONY: all
all:
	terraform apply

.PHONY: preview
preview:
	terraform plan

.PHONY: config
config:
	terraform remote config \
	    -backend=s3 \
	    -backend-config=bucket=travis-terraform-state \
	    -backend-config=key=terraform-config/aws-staging.tfstate \
	    -backend-config=region=us-east-1 \
	    -backend-config=encrypt=true
	terraform get
