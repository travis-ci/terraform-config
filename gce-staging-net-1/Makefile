AMQP_URL_COM_VARNAME := CLOUDAMQP_URL
AMQP_URL_ORG_VARNAME := CLOUDAMQP_GRAY_URL
ENV_SHORT := staging

include $(shell git rev-parse --show-toplevel)/gce.mk

WRITE_CONFIG_OPTS := --write-bastion --env-tail $(ENV_TAIL)

.PHONY: default
default: hello

CONFIG_FILES := \
	config/bastion.env \
	config/gce-workers-$(ENV_SHORT).json \
	config/worker-com.env \
	config/worker-org.env

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).auto.tfvars

$(CONFIG_FILES): config/.written config/.gce-keys-written
