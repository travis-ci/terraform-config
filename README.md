# terraform-config

This repository will contain all of our terraform configs as a monolithic repo.

## Usage

    cd env-staging

    export AWS_ACCESS_KEY=...
    export AWS_SECRET_KEY=...
    export AWS_REGION=us-east-1

    export TF_VAR_env_name=staging
    export TF_VAR_aws_bastion_ami=...
    export TF_VAR_aws_worker_ami=...
    export TF_VAR_aws_nat_ami=...

    ./init.sh

    terraform plan
    terraform apply
