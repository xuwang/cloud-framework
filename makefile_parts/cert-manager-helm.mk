################################################################################
# cert-manager.mk
# See https://github.com/jetstack/cert-manager/blob/master/docs/user-guides/deploying.md
# See https://github.com/kubernetes/charts/blob/master/stable/cert-manager/README.md
################################################################################
ifndef HELM
	export HELM := helm
endif

ifndef CERT_MANAGER_CHART_VERSION
	export CERT_MANAGER_CHART_VERSION := 0.5.2
endif

ifndef ACME_URL
	export ACME_URL := https://acme-staging.api.letsencrypt.org/directory
endif

ifndef ACME_EMAIL
	export ACME_EMAIL=${USER}@example.com
endif

ifndef CERT_MANAGER_NS
	export CERT_MANAGER_NS := kube-system
endif

# NOTE cert-manager is not currently support set up renew-before-days, but the defualt is 30 days.
# See https://github.com/jetstack/cert-manager/blob/ce9e5ede2bc6d8ccbc8e4db086f84c17e3f4d3af/docs/user-guides/acme-http-validation.md
ifndef CERT_RENEW_BEFORE_DAYS
	export CERT_RENEW_BEFORE_DAYS := 30
endif

ifndef TEMPLATES
	missing_vars := ${missing_vars} TEMPLATES
endif

ifndef EXTERNAL_DNS_GOOGLE_PROJECT
	EXTERNAL_DNS_GOOGLE_PROJECT=${GCP_PROJECT_ID}
endif

ifndef EXTERNAL_DNS_GCP_CREDENTIALS_PATH
	EXTERNAL_DNS_GCP_CREDENTIALS_PATH=secret/projects/${GCP_PROJECT_NAME}/common/dns-admin-key
endif

ifndef HELM_CHART_DIR
	HELM_CHART_DIR=${FRAMEWORK_DIR}/helm-charts
endif

### For CA Issuer
ifndef ISSUER_HELM_NAMESPACE
	ISSUER_HELM_NAMESPACE=${CERT_MANAGER_NS}
endif
ifndef ISSUER_HELM_RELEASE_NAME
	ISSUER_HELM_RELEASE_NAME := cert-issuer
endif
ifndef ISSUER_HELM_CHART
	ISSUER_HELM_CHART := cert-issuer
endif
ifndef ISSUER_HELM_CHART_VERSION
	ISSUER_HELM_CHART_VERSION := latest
endif

ifndef CA_COMMON_NAME
	CA_COMMON_NAME := "ca.example.com"
endif
ifndef CA_KEY_PATH
	CA_KEY_PATH=${SEC_PATH}/cert-issuer/${GCP_ENVIRONMENT}/ca.key
endif
ifndef CA_CERT_PATH
	CA_CERT_PATH=${SEC_PATH}/cert-issuer/${GCP_ENVIRONMENT}/ca.crt
endif

.PHONY: create-cert-manager-ns
create-cert-manager-ns: config-kube ## create cert-manager namespace
	@if ! kubectl get namespace ${CERT_MANAGER_NS} &> /dev/null ; then \
		kubectl create namespace ${CERT_MANAGER_NS} ; \
	fi

.PHONY: deploy-cert-manager
deploy-cert-manager: create-cert-manager-ns ## create the cert-manager
	@if ! ${HELM} ls cert-manager | grep DEPLOYED; \
	then \
		${HELM} repo update;  \
		${HELM} install \
			--name cert-manager \
			--namespace ${CERT_MANAGER_NS} \
			--set extraArgs={--cluster-resource-namespace=${CERT_MANAGER_NS}},webhook.enabled=false \
			--version ${CERT_MANAGER_CHART_VERSION} \
			stable/cert-manager; \
	fi

.PHONY: upgrade-cert-manager
upgrade-cert-manager: create-cert-manager-ns ## upgrade cert-manager
	${HELM} repo update
	${HELM} upgrade  \
		--set extraArgs={--cluster-resource-namespace=${CERT_MANAGER_NS}},webhook.enabled=false \
		--version ${CERT_MANAGER_CHART_VERSION} \
    	cert-manager stable/cert-manager

.PHONY: ls-cert-manager
ls-cert-manager: ## list the cert-manager
	@${HELM} ls --all cert-manager

.PHONY: cert-manager-status
cert-manager-status: ## check cert-manager status
	@${HELM} status cert-manager

.PHONY: destroy-cert-manager
destroy-cert-manager: config-kube ## destroy the  cert-manager
	@if ${HELM} ls cert-manager | grep cert-manager &>/dev/null; \
	then \
		${HELM} delete --purge cert-manager; \
	fi

#########################################################################
# Cert Issuers (local chart under ${SCRIPTS_DIR}/helm-charts/cert-issuer)
#########################################################################
.PHONY: deploy-cert-issuer
deploy-cert-issuer: config-kube ## deploy cert issuers
	@if ! helm ls ${ISSUER_HELM_RELEASE_NAME} | grep ${ISSUER_HELM_RELEASE_NAME} &>/dev/null ; \
	then \
		cat ${HELM_CHART_DIR}/${ISSUER_HELM_CHART}/${ISSUER_HELM_CHART_VERSION}/values.tmpl | render.sh | \
		${HELM} ${extra_global_args} \
			install -f - \
			--name ${ISSUER_HELM_RELEASE_NAME} \
			--namespace "${ISSUER_HELM_NAMESPACE}" \
			${HELM_CHART_DIR}/${ISSUER_HELM_CHART}/${ISSUER_HELM_CHART_VERSION} ; \
	fi
	
.PHONY: upgrade-cert-issuer
upgrade-cert-issuer: config-kube ## upgrade cert issuers
	@if ${HELM} ls ${ISSUER_HELM_RELEASE_NAME} | grep ${ISSUER_HELM_RELEASE_NAME} &>/dev/null; \
	then \
		cat ${HELM_CHART_DIR}/${ISSUER_HELM_CHART}/${ISSUER_HELM_CHART_VERSION}/values.tmpl | render.sh | \
		helm ${extra_global_args} \
			upgrade -f - \
			${ISSUER_HELM_RELEASE_NAME} \
			${HELM_CHART_DIR}/${ISSUER_HELM_CHART}/${ISSUER_HELM_CHART_VERSION} ; \
	fi

.PHONY: destroy-cert-issuer
destroy-cert-issuer: config-kube ## destroy cert issuers
	@if ${HELM} ls ${ISSUER_HELM_RELEASE_NAME} | grep ${ISSUER_HELM_RELEASE_NAME} &>/dev/null; \
	then \
		${HELM} delete --purge ${ISSUER_HELM_RELEASE_NAME} ; \
	fi

.PHONY: show-cert-issuer
show-cert-issuer: ## show cert issuers
	@kubectl get clusterissuer,issuer --all-namespaces

.PHONY: create-issuer-ca
create-issuer-ca: vault-login ## Generate a Issuer CA private key and cert and save to vault
	openssl genrsa -out ca.key 2048
	# Try two possible openssl.cnf file for a valid v3_ca extention
	# See https://github.com/jetstack/cert-manager/issues/279.
	openssl req -x509 -new -nodes -key ca.key -subj "/CN=${CA_COMMON_NAME}" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt -config /usr/local/etc/openssl/openssl.cnf || \
	openssl req -x509 -new -nodes -key ca.key -subj "/CN=${CA_COMMON_NAME}" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt -config /etc/ssl/openssl.cnf
	vault-write.sh ${CA_KEY_PATH} @ca.key
	vault-write.sh ${CA_CERT_PATH} @ca.crt
	rm -f ca.key ca.crt

## end of cert-manager.mk
