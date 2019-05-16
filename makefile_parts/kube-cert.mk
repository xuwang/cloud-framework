################################################################################
# cert.mk
################################################################################

ifndef TEMPLATES
	missing_vars := ${missing_vars} TEMPLATES
endif

ifndef CERT_TEMPLATES
	export CERT_TEMPLATES=${TEMPLATES}
endif

.PHONY: kube-cert
kube-cert: config-kube ## create certs defined in ${TEMPLATES}/certs.yml
	@if [ -a ${CERT_TEMPLATES}/cert.yml ]; then \
		kube_apply.sh ${CERT_TEMPLATES}/cert.yml ; \
	fi	
	@if [ -a ${CERT_TEMPLATES}/certs.yml ]; then \
		kube_apply.sh ${CERT_TEMPLATES}/certs.yml ; \
	fi
	@for i in ${CERT_TEMPLATES}/*-cert.yml; do \
		kube_apply.sh $$i ; \
	done

.PHONY: destroy-kube-cert
destroy-kube-cert: config-kube ## destroy certs defined in ${TEMPLATES}/certs.yml
	@if [ -a ${CERT_TEMPLATES}/cert.yml ]; then \
		kube_delete.sh ${CERT_TEMPLATES}/cert.yml ; \
	fi
	@if [ -a ${CERT_TEMPLATES}/certs.yml ]; then \
		kube_delete.sh ${CERT_TEMPLATES}/certs.yml ; \
	fi
	@for i in ${CERT_TEMPLATES}/*-cert.yml; do \
		kube_delete.sh $$i ; \
	done

.PHONY: update-kube-cert
update-kube-cert: destroy-kube-cert kube-cert ## update certs
	@echo "NOTE: cert secrets and cert consumers may also need to be recycled to pickup the new cert"

.PHONY: ls-cert-issuer
ls-cert-issuer: ## list all cert issuers
	kubectl get ClusterIssuer,Issuer --all-namespaces

.PHONY: ls-kube-cert
ls-kube-cert: ## list all certificates
	kubectl get certificates --all-namespaces

.PHONY: get-kube-cert
get-kube-cert: ## get all certificates
	kubectl get certificates --all-namespaces -o yaml

.PHONY: show-kube-cert
show-kube-cert: ## show cert in app namespace
	@show-kube-cert.sh ${APP_NAMESPACE}

## end of cert-manager.mk
