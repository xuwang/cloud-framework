ifndef GCP_PROJECT_ID
	_ := $(error var GCP_PROJECT_ID not set)
endif

ifndef AUDIT_CONFIG_FILE
	ifeq ($(wildcard ../common),)
		AUDIT_CONFIG_FILE := gcp-config/audit.yaml
	else
		AUDIT_CONFIG_FILE := ../common/gcp-config/audit.yaml
	endif
endif

.PHONY: audit-logging
audit-logging: config-gcloud-user ## set which services have data read/write audit logs with audit.yaml
	@${SCRIPTS_DIR}/audit-logging-set.sh ${AUDIT_CONFIG_FILE}
