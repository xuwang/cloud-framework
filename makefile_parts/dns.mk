

################################################################################
# DEPRECATED
# dns.mk
# RESOURCE_TYPE is svc or ing
# ifndef RESOURCE_TYPE
# 	(error RESOURCE_TYPE not set)
# endif

# RESOURCE_NAME is name of svc or ing like vault-svc
# ifndef RESOURCE_NAME
# 	(error RESOURCE_NAME not set)
# endif
################################################################################

.PHONY: dns-update
dns-update: dns-dereg dns-reg ## deregister and register DNS

.PHONY: dns-reg
dns-reg: ## register DNS
	@echo It may take a few minutes for service to setup ingress and register with DNS ....
	@${SCRIPTS_DIR}/dns-reg.sh ${GCP_DNS_ZONE} ${APP_FQDN} \
		$(shell ${SCRIPTS_DIR}/get-svc-ip.sh ${RESOURCE_TYPE} ${RESOURCE_NAME})

.PHONY: dns-dereg
dns-dereg: ## deregister dns
	@${SCRIPTS_DIR}/dns-dereg.sh ${GCP_DNS_ZONE} ${APP_FQDN} || true

.PHONY: dns-rec
dns-rec: ## show app dns record
	gcloud dns record-sets list -z ${GCP_DNS_ZONE}  --format json | jq ".[] | select(.name == \"${APP_FQDN}\")"
