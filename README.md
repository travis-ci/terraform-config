# terraform-config

This contains all of the Terraform bits for hosted Travis CI :cloud:.

This is what allows us to manage our cloud environments from a central place,
and change them over time. It should be possible to bring up (or re-create) a
complete environment with a few `make` tasks.

## Status

In production.  Patches welcome.  Please review the [code of
conduct](./CODE_OF_CONDUCT.md).

## Infrastructure

Terraform manages pretty much everything that is not running on Heroku, and even
a little bit of some of what is running on Heroku.  We use terraform to manage
our main cloud environments as well as some other services:

* Amazon Web Services
* Google Cloud Platform
* Macstadium
* OpenStack
* Packet

## Requirements

* [terraform](https://www.terraform.io/) 0.9.0+
* `trvs`, a Travis CI tool shrouded in mystery, along with access to
  secret secrets for making secret stuff
* Ruby 2.2 or higher (to make sure trvs functions correctly)
* [jq](https://stedolan.github.io/jq/)


## Set-up

* Clone this repo
* Make sure `trvs` is installed and added to your `$PATH`. (You can try running
  `trvs generate-config -H travis-scheduler-prod` to check)
* Set all required environment variables (see the list below). This can achieved
  by doing something like:
	* Manually sourcing an `.env` file (like `.example.env`)
	* Using [autoenv](https://github.com/kennethreitz/autoenv)
	* Fetching values from your own pass vault

#### Required environment variables

* `AWS_ACCESS_KEY`
* `AWS_REGION`
* `AWS_SECRET_KEY`
* `GITHUB_TOKEN`
* `GITHUB_USERNAME`
* `HEROKU_API_KEY`
* `SLACK_WEBHOOK` (may be retrieved via `trvs generate-config -n -f env terraform-config -p '' terraform_common`)
* `TF_VAR_ssh_user`
* `TRAVIS_KEYCHAIN_DIR` - should be the parent directory of your keychain repos

#### Notes

MacStadium & GCE access creds are shared and come from keychain, not
personal accounts, so there are no infrastructure-specific access keys
for them.

`$TF_VAR_ssh_user` isn't needed for AWS and can just be set to `$USER`, if your
local username and your SSH username are the same. If you have an SSH key
passphrase, consider starting `ssh-agent` and doing `ssh-add`.

See http://rabexc.org/posts/using-ssh-agent for more details.


## Usage

``` bash
# move into a given infrastructure directory, e.g.:
cd ./gce-staging-1

# terraform plan, which will automatically configure terraform from remote and
# generate config files via `trvs`
make plan

# if it looks OK, terraform apply
make apply

# as some configuration is generated and cached locally, changes to
# configuration sources may require cleaning before further plan/apply
make clean
```

## Troubleshooting tips

* Running `make check` will verify a few common setup requirements.
* Verify you have been added to the relevant Heroku organizations.
* Try passing the `-d` flag to `make` to see which commands are being
run.
	* this will show various curl commands (e.g. heroku) which may be
	silenced (`-fs`); try running these directly without the `-fs`
	flags to make sure they succeed
* `terraform console` will allow you to use an interactive console for
  testing interpolations and looking into the existing state.
* Terraform state errors may be due to insufficient AWS permissions.  See the
  [`.example-aws-iam-policy.json`](./.example-aws-iam-policy.json) for example
minimum permissions.

## License

See [`./LICENSE`](./LICENSE).
