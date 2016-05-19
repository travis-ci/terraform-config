# terraform-config

This repository will contain all of our terraform configs as a monolithic repo.

This is what allows us to manage our cloud environments from a central place, and change them over time. It should be possible to bring up (or re-create) a complete environment with the push of a button.

## Status

Prototype (not yet in production)

## Infrastructure

Terraform manages pretty much everything that is not running on Heroku. We build images using Packer and then spin up instances in our cloud environments based on those images.

We use terraform to manage our main cloud environments as well as some other services:

* Amazon Web Services
* Google Cloud Platform
* (Hopefully more soon)

## Requirements

* [terraform](https://www.terraform.io/)

## Usage

    cd env-staging

    cp .example.env .env
    cat .env
    # edit .env
    source .env

    # setup terraform remote and module config
    make config

    # terraform plan
    make preview

    # terraform apply
    make
