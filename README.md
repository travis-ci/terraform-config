# terraform-config

This repository will contain all of our terraform configs as a monolithic repo.

## Usage

    cd env-staging

    cp .example.env .env
    cat .env
    # edit .env
    source .env

    ./init.sh

    terraform get
    terraform plan
    terraform apply
