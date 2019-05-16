ifndef GCP_CONFIG_DIR
	ifeq ($(wildcard ../common),)
		GCP_CONFIG_DIR := gcp-config
	else
		GCP_CONFIG_DIR := ../common/gcp-config
	endif
endif

ifndef KMS_KEYRINGS_DIR
	KMS_KEYRINGS_DIR := ${GCP_CONFIG_DIR}/kms-keyrings
endif

# .PHONY: kms-setup
# kms-setup: config-gcloud-user ## create kms keyrings/keys  and set IAM based on ${KMS_KEYRINGS_FILE}
# 	@${SCRIPTS_DIR}/kms-create.sh ${KMS_KEYRINGS_DIR}

.PHONY: setup-keyrings
setup-keyrings: ## create kms keyrings/keys and set IAM based on ${KMS_KEYRINGS_DIR}/<keyring>.json
	${SCRIPTS_DIR}/kms-setup-keyring.sh ${KMS_KEYRINGS_DIR}
