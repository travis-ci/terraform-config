AMQP_URL_VARNAME := RABBITMQ_BIGWIG_RX_URL
ENV_SHORT := staging

include $(shell git rev-parse --show-toplevel)/aws.mk

.PHONY: default
default: hello

.PHONY: .config
.config: $(ENV_NAME).auto.tfvars
