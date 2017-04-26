# terraform-config

This repository will contain all of our terraform configs as a monolithic repo.

This is what allows us to manage our cloud environments from a central place,
and change them over time. It should be possible to bring up (or re-create) a
complete environment with the push of a button.

## Status

In production, with mixed adoption across infrastructures.

## Infrastructure

Terraform manages pretty much everything that is not running on Heroku. We build
images using Packer and then spin up instances in our cloud environments based
on those images.

We use terraform to manage our main cloud environments as well as some other
services:

* Amazon Web Services
* Google Cloud Platform
* (Hopefully more soon)

## Requirements

* [terraform](https://www.terraform.io/) 0.9.0+
* `trvs`, a Travis CI tool shrouded in mystery, along with access to secret
  secrets for making secret stuff

## Usage

``` bash
cp .example.env .env

# edit, then source .env
source .env

# or, if using autoenv:
cd .

# move into a given infrastructure directory, e.g.:
cd ./gce-staging-1

# terraform plan, which will automatically configure terraform from remote and
# generate config files via `trvs`
make plan

# if it looks OK, terraform apply
make apply
```
