AMQP_URL_COM_VARNAME := CLOUDAMQP_URL
AMQP_URL_ORG_VARNAME := CLOUDAMQP_GRAY_URL
ENV_SHORT := production
CA_PEMS := config/docker-ca-key.pem config/docker-ca.pem
TOP := $(shell git rev-parse --show-toplevel)

include $(TOP)/terraform-common.mk
include $(TOP)/trvs.mk

.config: $(CA_PEMS) $(ENV_NAME).auto.tfvars $(TRVS_INFRA_ENV_TFVARS)

$(TRVS_INFRA_ENV_TFVARS):
	trvs generate-config -f json -a terraform-config -e terraform_common -o $@

config/docker-ca-key.pem: config
	cp -v $(TRAVIS_KEYCHAIN_DIR)/travis-pro-keychain/keys/$(notdir $@) $@

config/docker-ca.pem: config
	cp -v $(TRAVIS_KEYCHAIN_DIR)/travis-pro-keychain/keys/$(notdir $@) $@

config:
	mkdir -p $@
