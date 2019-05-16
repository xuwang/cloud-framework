
ifndef SERVICE_ACCOUNTS_DIR
	ifeq ($(wildcard ../common),)
		SERVICE_ACCOUNTS_DIR := gcp-config/service-accounts
	else
		SERVICE_ACCOUNTS_DIR := ../common/gcp-config/service-accounts
	endif
endif


.PHONY: service-accounts
service-accounts: config-gcloud-user ## create service accounts from ${SERVICE_ACCOUNTS_DIR}
	@${SCRIPTS_DIR}/service-accounts-create.sh ${SERVICE_ACCOUNTS_DIR}