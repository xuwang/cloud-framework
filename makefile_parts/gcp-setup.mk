################################################################################
## gcp-setup.mk
# Targets for general setting up GCP Project 
################################################################################

ifndef GCP_CONFIG_DIR
	ifeq ($(wildcard ../common),)
		GCP_CONFIG_DIR := gcp-config
	else
		GCP_CONFIG_DIR := ../common/gcp-config
	endif
endif

ifndef SERVICE_ACCOUNTS_DIR
	SERVICE_ACCOUNTS_DIR=${GCP_CONFIG_DIR}/service-accounts
endif

ifndef BUCKETS_DIR
	BUCKETS_DIR=${GCP_CONFIG_DIR}/buckets
endif

.PHONY: enable-services
enable-services: ## enable gcp services/api defined in ${GCP_CONFIG_DIR}/gcp-services.txt
	@${SCRIPTS_DIR}/enable-gcp-services.sh ${GCP_CONFIG_DIR}/gcp-services.txt

.PHONY: setup-service-accounts
setup-service-accounts: ## setup all service account defined in SERVICE_ACCOUNTS_DIR
	@${SCRIPTS_DIR}/service-accounts-setup.sh ${SERVICE_ACCOUNTS_DIR}

.PHONY: destroy-service-accounts
destroy-service-accounts: ## delete all service account defined in SERVICE_ACCOUNTS_DIR
	@${SCRIPTS_DIR}/service-accounts-delete.sh ${SERVICE_ACCOUNTS_DIR}

.PHONY: setup-buckets
setup-buckets: ## setup all storage buckets defined in SERVICE_ACCOUNTS_DIR
	@${SCRIPTS_DIR}/storage-setup-buckets.sh ${BUCKETS_DIR}