

################################################################################
# external-dns.mk
################################################################################

ifndef TEMPLATES
	missing_vars := ${missing_vars} TEMPLATES
endif

ifndef EXTERNAL_DNS_IMAGE
	missing_vars := ${missing_vars} EXTERNAL_DNS_IMAGE
endif

ifndef EXTERNAL_DNS_GOOGLE_PROJECT
	EXTERNAL_DNS_GOOGLE_PROJECT=${GCP_PROJECT_ID}
endif

ifndef EXTERNAL_DNS_GCP_CREDENTIALS_PATH
	EXTERNAL_DNS_GCP_CREDENTIALS_PATH=secret/projects/${GCP_PROJECT_NAME}/common/dns-admin-key
endif

ifndef GKE_CLUSTER_NAME
	missing_vars := ${missing_vars} GKE_CLUSTER_NAME
endif

.PHONY: deploy-external-dns
deploy-external-dns: config-kube kube-sec ## provisioning the external-dns
	@${SCRIPTS_DIR}/kube_apply.sh ${TEMPLATES}/deployment-external-dns.yml

.PHONY: update-external-dns
update-external-dns: deploy-external-dns  ## update the external-dns

.PHONY: destroy-external-dns
destroy-external-dns: config-kube ## destroy the external-dns
	@${SCRIPTS_DIR}/kube_delete.sh ${TEMPLATES}/deployment-external-dns.yml

.PHONY: test-external-dns
test-external-dns: config-kube  ## deploy dns test pod/service
	@${SCRIPTS_DIR}/kube_apply.sh ${TEMPLATES}/test-external-dns.yml

.PHONY: destroy-test-external-dns
destroy-test-external-dns: config-kube  ## destroy dns test pod/service
	@${SCRIPTS_DIR}/kube_delete.sh ${TEMPLATES}/test-external-dns.yml

## end of external-dns.mk
