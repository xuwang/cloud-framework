
ifndef FIREWALL_RULES_DIR
	ifeq ($(wildcard ../common),)
		FIREWALL_RULES_DIR := gcp-config/firewall-rules/create
	else
		FIREWALL_RULES_DIR := ../common/gcp-config/firewall-rules/create
	endif
endif

ifndef FIREWALL_RULES_DELETE_FILE
	ifeq ($(wildcard ../common),)
		FIREWALL_RULES_DELETE_FILE := gcp-config/firewall-rules/delete.yaml
	else
		FIREWALL_RULES_DELETE_FILE := ../common/gcp-config/firewall-rules/delete.yaml
	endif
endif

.PHONY: firewall-rules
firewall-rules: config-gcloud-user ## create firewall rules with ${FIREWALL_RULES_DIR}
	@${SCRIPTS_DIR}/firewall-rules-delete.sh ${FIREWALL_RULES_DELETE_FILE}
	@${SCRIPTS_DIR}/firewall-rules-create.sh ${FIREWALL_RULES_DIR}