################################################################################
# cert-manager.mk
# See https://github.com/jetstack/cert-manager/blob/master/docs/user-guides/deploying.md
# See https://github.com/kubernetes/charts/blob/master/stable/cert-manager/README.md
################################################################################

ifndef ACME_URL
	export ACME_URL := https://acme-staging.api.letsencrypt.org/directory
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
	EXTERNAL_DNS_GOOGLE_PROJECT := clever-circlet-125504
endif

### For CA Issuer
ifndef CA_COMMON_NAME
	CA_COMMON_NAME := "ca.example.com"
endif
ifndef CA_KEY_PATH
	CA_KEY_PATH="${SEC_PATH}/cert-issuer/${GCP_ENVIRONMENT}/ca.key"
endif
ifndef CA_CERT_PATH
	CA_CERT_PATH="${SEC_PATH}/cert-issuer/${GCP_ENVIRONMENT}/ca.crt"
endif

.PHONY: create-cert-manager-ns
cert-manager-ns: config-kube ## create cert-manager namespace
	@if ! kubectl get namespace ${CERT_MANAGER_NS} &> /dev/null ; then \
		kubectl create namespace ${CERT_MANAGER_NS} ; \
	fi

.PHONY: deploy-cert-manager
deploy-cert-manager: cert-manager-ns ## create the cert-manager
	@for i in ${TEMPLATES}/cert-manager/without-rbac/*.yaml; do \
		kube_apply.sh $$i ; \
	done

.PHONY: destroy-cert-manager
destroy-cert-manager: config-kube ## destroy the  cert-manager
	@for i in ${TEMPLATES}/cert-manager/without-rbac/*.yaml; do \
		kube_delete.sh $$i ; \
	done

.PHONY: deploy-cert-issuer
deploy-cert-issuer: kube-sec ## deploy cert issuers
	@kube_apply.sh ${TEMPLATES}/cert-issuer.yml

.PHONY: destroy-cert-issuer
destroy-cert-issuer: config-kube ## destroy cert issuers
	@kube_delete.sh ${TEMPLATES}/cert-issuer.yml

.PHONY: show-issuer
show-cert-issuer: ## show cert issuers
	@kubectl get clusterissuer,issuer --all-namespaces

.PHONY: create-ca
create-ca: vault-login ## Generate a CA private key and cert and save to vault
	openssl genrsa -out ca.key 2048
	openssl req -x509 -new -nodes -key ca.key -subj "/CN=${CA_COMMON_NAME}" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt
	vault-write.sh ${CA_KEY_PATH} @ca.key
	vault-write.sh ${CA_CERT_PATH} @ca.crt
	rm -f ca.key ca.crt

## end of cert-manager.mk
