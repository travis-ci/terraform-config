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
