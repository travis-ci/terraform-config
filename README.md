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
* Macstadium
* (Hopefully more soon)

## Requirements

* [terraform](https://www.terraform.io/) 0.9.0+
* `trvs`, a Travis CI tool shrouded in mystery, along with access to
  secret secrets for making secret stuff
* Ruby 2.2 or higher (to make sure trvs functions correctly)
* [jq](https://stedolan.github.io/jq/)


## Set-up

* Clone this repo
* Clone the keychain repositories
* Make sure trvs is installed and added to your $PATH. (You can try
running `trvs generate-config -H travis-scheduler-prod` to check)
* Set all required environment variables (see the list below). This
can be achieved by either:
	* Manually sourcing an .env file (like .example.env)
	* Using [autoenv](https://github.com/kennethreitz/autoenv)
	* Fetching them from your own pass vault

#### Required environment variables

* TRAVIS_KEYCHAIN_DIR  - should to  be the parent directory of your keychain
repos
* GITHUB_TOKEN
* GITHUB_USERNAME
* AWS_ACCESS_KEY
* AWS_SECRET_KEY
* AWS_REGION
* HEROKU_API_KEY
* TF_VAR_ssh_user

#### Notes

MacStadium & GCE access creds are shared and come from keychain, not
personal accounts, so there are no infrastructure-specific access keys
for them.

$TF_VAR_ssh_user isn't needed for AWS and can just be set to $USER, if
your local username and your SSH username are the same. If you have an
SSH key passphrase, consider starting `ssh-agent` and doing `ssh-add`.

See http://rabexc.org/posts/using-ssh-agent for more details.


## Usage

``` bash
# move into a given infrastructure directory, e.g.:
cd ./gce-staging-1

# terraform plan, which will automatically configure terraform from remote and
# generate config files via `trvs`
make clean plan

# if it looks OK, terraform apply
make apply
```


## Troubleshooting tips

* Verify you have been added to both com and pro Heroku organizations
* Try passing the `-d` flag to `make` to see which commands are being
run
	* this will show various curl commands (e.g. heroku) which may be
	silenced (`-fs`); try running these directly without the `-fs`
	flags to make sure they succeed
* `terraform console` will allow you to use an interactive console for
  testing interpolations and looking into the existing state
