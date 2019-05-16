################################################################################
## kube-sec.mk
# Targets for kubernetes secret ops
################################################################################

ifndef KUBE_SEC_DEF_FILE
	export KUBE_SEC_DEF_FILE=${TEMPLATES}/secret.yml
endif

.PHONY: kube-sec
kube-sec: vault-login config-kube  ## create kubernetes secret from ${TEMPLATES}/secret.yml
	@if [ -a ${KUBE_SEC_DEF_FILE} ]; then \
		cat ${KUBE_SEC_DEF_FILE} | render.sh | ${SCRIPTS_DIR}/vault2kube.sh | kubectl apply --overwrite=true -f - ; \
	fi

.PHONY: check-kube-sec
check-kube-sec: ## check the generated secret.yml
	@if [ -a ${KUBE_SEC_DEF_FILE} ]; then \
		cat ${KUBE_SEC_DEF_FILE} | render.sh ; \
	fi

.PHONY: check-kube-sec-values
check-kube-sec-values: vault-login config-kube ## check the generated secret.yml with secrets!
	@if [ -a ${KUBE_SEC_DEF_FILE} ]; then \
		cat ${KUBE_SEC_DEF_FILE} | render.sh | ${SCRIPTS_DIR}/vault2kube.sh ; \
	fi

.PHONY: destroy-kube-sec
destroy-kube-sec: vault-login config-kube ## destroy kubernetes secret defined by ${TEMPLATES}/secret.yml
	@if [ -a ${KUBE_SEC_DEF_FILE} ]; then \
		cat ${KUBE_SEC_DEF_FILE} | render.sh | ${SCRIPTS_DIR}/vault2kube.sh  \
			| kubectl delete --ignore-not-found -f -  ; \
	fi


.PHONY: kube-sec-reg
kube-sec-reg: destroy-kube-sec-reg
	@kubectl create secret docker-registry ${DOCKER_REGISTRY} \
		-n ${APP_NAMESPACE} \
		--docker-server=${DOCKER_REGISTRY} \
		--docker-username=${DOCKER_REGISTRY_USERNAME} \
		--docker-password=$$(vault-read.sh ${DOCKER_REGISTRY_PASSWORD_PATH})  \
		--docker-email=${DOCKER_REGISTRY_USERNAME}

.PHONY: destroy-kube-sec-reg
destroy-kube-sec-reg: config-kube
	@kubectl delete secret ${DOCKER_REGISTRY} \
		--ignore-not-found \
		-n ${APP_NAMESPACE} \