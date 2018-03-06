AMQP_URL_VARNAME := CLOUDAMQP_URL
ENV_SHORT := production

include $(shell git rev-parse --show-toplevel)/gce.mk

PROD_TF_VERSION := v0.11.2
TERRAFORM := $(HOME)/.cache/travis-terraform-config/terraform-$(PROD_TF_VERSION)
