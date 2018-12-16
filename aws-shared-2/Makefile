AMQP_URL_COM_VARNAME := CLOUDAMQP_URL
AMQP_URL_ORG_VARNAME := CLOUDAMQP_GRAY_URL
ENV_SHORT := production

include $(shell git rev-parse --show-toplevel)/aws.mk

.PHONY: default
default: hello

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars
