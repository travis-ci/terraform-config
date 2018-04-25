TOP := $(shell git rev-parse --show-toplevel)

include $(TOP)/terraform-common.mk
include $(TOP)/trvs.mk

.PHONY: default
default: hello

CONFIG_FILES := \
	config/travis-build-com.env \
	config/travis-build-org.env \
	config/travis-com.env \
	config/travis-org.env \
	config/worker-com.env \
	config/worker-org.env

.PHONY: .config
.config: $(CONFIG_FILES) $(ENV_NAME).auto.tfvars

$(CONFIG_FILES): config/.written

.PHONY: diff-docker-images
diff-docker-images:
	@diff -u \
		--label a/docker-images \
		<($(TOP)/bin/show-current-docker-images) \
		--label b/docker-images \
		<($(TOP)/bin/show-proposed-docker-images "$(ENV_NAME).auto.tfvars")
