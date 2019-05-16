

################################################################################
# external-dns.mk
################################################################################

ifndef TEMPLATES
	missing_vars := ${missing_vars} TEMPLATES
endif

ifndef HELM
	export HELM := helm
endif

ifndef EXTERNAL_DNS_GOOGLE_PROJECT
	export EXTERNAL_DNS_GOOGLE_PROJECT=${GCP_PROJECT_ID}
endif

ifndef EXTERNAL_DNS_GCP_CREDENTIALS_PATH
	export EXTERNAL_DNS_GCP_CREDENTIALS_PATH=secret/projects/${GCP_PROJECT_NAME}/common/dns-admin-key
endif

ifndef EXTERNAL_DNS_NS
	export EXTERNAL_DNS_NS := kube-system
endif

ifndef GKE_CLUSTER_NAME
	missing_vars := ${missing_vars} GKE_CLUSTER_NAME
endif

ifndef ACME_DNS_PROVIDER
	ACME_DNS_PROVIDER=${EXTERNAL_DNS_GOOGLE_PROJECT}-dns
endif

.PHONY: create-external-dns-ns
create-external-dns-ns: config-kube ## create cert-manager namespace
	@if ! kubectl get namespace ${EXTERNAL_DNS_NS} &> /dev/null ; then \
		kubectl create namespace ${EXTERNAL_DNS_NS} ; \
	fi

.PHONY: deploy-external-dns
deploy-external-dns: EXTERNAL_DNS_VERSION=v0.7.5
deploy-external-dns: EXTERNAL_DNS_GCP_CREDENTIALS=""
deploy-external-dns: vault-login
deploy-external-dns: create-external-dns-ns ## provisioning the external-dns
	@if ! ${HELM} ls external-dns | grep external-dns &>/dev/null ; \
	then \
		EXTERNAL_DNS_GCP_CREDENTIALS=`vault-read.sh ${EXTERNAL_DNS_GCP_CREDENTIALS_PATH}` ; \
		cat ${FRAMEWORK_DIR}/helm-charts/external-dns/latest/values.tmpl | render.sh \
		| ${HELM} install \
			-f - \
			--name external-dns \
			--namespace ${EXTERNAL_DNS_NS} \
			--version ${EXTERNAL_DNS_VERSION} \
			stable/external-dns ; \
	fi
	
.PHONY: upgrade-external-dns
upgrade-external-dns: EXTERNAL_DNS_VERSION=v0.7.5
upgrade-external-dns: EXTERNAL_DNS_GCP_CREDENTIALS=""
upgrade-external-dns: vault-login
upgrade-external-dns: config-kube ## update the external-dns
	@EXTERNAL_DNS_GCP_CREDENTIALS=`vault-read.sh ${EXTERNAL_DNS_GCP_CREDENTIALS_PATH}` ; \
	cat ${FRAMEWORK_DIR}/helm-charts/external-dns/latest/values.tmpl | render.sh \
		| ${HELM} upgrade --version ${EXTERNAL_DNS_VERSION} \
		-f - \
		external-dns stable/external-dns

.PHONY: destroy-external-dns
destroy-external-dns: config-kube ## destroy the external-dns
	@if ${HELM} ls external-dns | grep external-dns &>/dev/null; \
	then \
		${HELM} del --purge external-dns; \
	fi

###########
## Test
###########
.PHONY: test-external-dns-ingress
test-external-dns-ingress: vault-login config-kube ## deploy dns test (ingress) pod/service
	@helm_chart=external-dns-test-ingress \
		helm_release_name=external-dns-test-ingress \
		${SCRIPTS_DIR}/helm-install.sh
	@echo Test URL http://external-dns-ing.${GCP_DNS_DOMAIN}

.PHONY: destroy-test-external-dns-ingress
destroy-test-external-dns-ingress: vault-login config-kube ## destroy dns test (ingress) pod/service
	@helm_release_name=external-dns-test-ingress \
		${SCRIPTS_DIR}/helm-delete.sh 

.PHONY: test-external-dns-service
test-external-dns-service: vault-login config-kube ## deploy dns test (service) pod/service
	@helm_chart=external-dns-test-service \
		helm_release_name=external-dns-test-service \
		${SCRIPTS_DIR}/helm-install.sh 
	@echo Test URL http://external-dns-svc.${GCP_DNS_DOMAIN}

.PHONY: destroy-test-external-dns-service
destroy-test-external-dns-service: vault-login config-kube ## destroy dns test (service) pod/service
	@helm_release_name=external-dns-test-service \
		${SCRIPTS_DIR}/helm-delete.sh 

.PHONY: test-external-dns
test-external-dns: test-external-dns-service ## deploy dns test (service) pod/service

.PHONY: destroy-test-external-dns
destroy-test-external-dns: destroy-test-external-dns-service ## destroy dns test (service) pod/service

## end of external-dns.mk
