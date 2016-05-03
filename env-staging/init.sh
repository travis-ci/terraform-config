#!/bin/bash

terraform remote config -backend=s3 -backend-config=bucket=travis-terraform-state -backend-config=key=terraform-config/env-staging.tfstate -backend-config=region=$AWS_REGION -backend-config=encrypt=true
