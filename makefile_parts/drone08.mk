## drone08.mk
# Note is make file works with drone v0.8/drone cli v0.9

ifndef DRONE_CLI_VERSION
	export DRONE_CLI_VERSION=0.8
endif

ifndef DRONE_SERVER
	export DRONE_SERVER := https://ci.example.com
endif

ifndef DRONE_REPO
	missing_vars := ${missing_vars} DRONE_REPO
endif

ifndef DRONE_APPROLE
	export DRONE_APPROLE=drone-${GCP_PROJECT_NAME}-viewer
endif

ifndef DRONE_SEC_FILE
	export DRONE_SEC_FILE=.drone.sec
endif

ifndef DRONE_REGISTRY_FILE
	export DRONE_REGISTRY_FILE=.drone.reg
endif

ifndef DRONE_REPO_ADDRESS
	export DRONE_REPO_ADDRESS=${DRONE_URL}/${DRONE_REPO}
endif


# TODO-VARS: IF DRONE_TOKEN is really required, should we check for it?
ifneq ($(DRONE),true) # not in a drone job
	ifndef DRONE_TOKEN
		ifndef DRONE_TOKEN_FILE
			export DRONE_TOKEN_FILE := ${HOME}/.drone-token
		endif

		ifneq ("$(wildcard ${DRONE_TOKEN_FILE})", "")
			export DRONE_TOKEN=$(shell cat ${DRONE_TOKEN_FILE})
		endif
	endif
else
	export DRONE_TOKEN="no-drone-access"
endif

ifndef PUSH_TAG_PREFIX
	export PUSH_TAG_PREFIX := prod
endif

.PHONY: drone-init
drone-init:
	@if ! drone --version | grep ${DRONE_CLI_VERSION} &> /dev/null ; then \
		echo "ERROR: drone cli version ${DRONE_CLI_VERSION} is required!" ; \
		false ; \
	fi
	@if [ -z ${DRONE_TOKEN} ] ; then \
		echo "ERROR: DRONE_TOKEN is not set!" ; \
		false ; \
	fi

.PHONY: drone-add-repo
drone-add-repo: vault-login drone-init ## add repo to drone
	@if ! drone repo ls ${DRONE_REPO} | grep "^${DRONE_REPO}$$" &> /dev/null; then \
		drone repo add ${DRONE_REPO}; \
	fi

.PHONY: drone-ls-repo
drone-ls-repo: vault-login drone-init ## list repos in drone
	@drone repo ls ${DRONE_REPO}

.PHONY: drone-rm-repo
drone-rm-repo: drone-init ## remove repo from drone
	@if drone repo ls ${DRONE_REPO} | grep "^${DRONE_REPO}$$"  &> /dev/null; then \
		drone repo rm ${DRONE_REPO}; \
	fi

.PHONY: drone-ls-sec
drone-ls-sec: drone-init ## list CI/CD secrets
	@drone secret ls -repository ${DRONE_REPO}

.PHONY: drone-add-sec
drone-add-sec: vault-login drone-init drone-add-repo  ## add CI/CD secrets defined in DRONE_SEC_FILE
	${SCRIPTS_DIR}/drone-add-all-sec.sh ${DRONE_SEC_FILE}

.PHONY: drone-rm-sec
drone-rm-sec: drone-init ${DRONE_SEC_FILE} ## remove CI/CD secrets defined in DRONE_SEC_FILE
	@${SCRIPTS_DIR}/drone-rm-all-sec.sh ${DRONE_SEC_FILE}

.PHONY: drone-ls-registry
drone-ls-registry:  drone-init ## list CI/CD docker registries
	@drone registry ls -repository ${DRONE_REPO}

.PHONY: drone-add-registry
drone-add-registry: drone-init drone-add-repo  ## add CI/CD docker registries
	${SCRIPTS_DIR}/drone-add-registry.sh ${DRONE_REGISTRY_FILE}

.PHONY: drone-rm-registry
drone-rm-registry: drone-init  ## remove CI/CD docker registries
	@${SCRIPTS_DIR}/drone-rm-registry.sh ${DRONE_REGISTRY_FILE}

.PHONY: drone-logs
drone-logs: drone-init ## show logs from latest drone build
	drone build logs ${DRONE_REPO} \
		$$(drone build last ${DRONE_REPO} --format '{{ .Number }}')

.PHONY: drone-build-info
drone-build-info: drone-init  ## list CI/CD builds
	drone build ls --limit 1 ${DRONE_REPO}

.PHONY: drone-repair
drone-repair: drone-init ## repair drone repository webhooks
	@drone repo repair ${DRONE_REPO}

.PHONY: drone-setup
drone-setup: drone-add-repo drone-repair  ## set drone jobs and secrets
	@if [ -a ${DRONE_REGISTRY_FILE} ]; then \
		make drone-add-registry ; \
	fi
	@if [ -a ${DRONE_SEC_FILE} ]; then \
		make drone-add-sec ; \
	fi

.PHONY: drone-rebuild
drone-rebuild: drone-init  ## drone rebuild last job
	drone build start ${DRONE_REPO} `drone build ls -limit 1 -format '{{.Number}}' ${DRONE_REPO}` 

.PHONY: push-new-tag
push-new-tag: ## tag HEAD w/ the current date time and push the tag to deploy to drone production pipeline (if set up)
	@if git tag --contains HEAD | grep -q "^${PUSH_TAG_PREFIX}"; then \
		prefixed_tags=$$(git tag --contains HEAD | grep "^${PUSH_TAG_PREFIX}"); \
		>&2 echo "already tag(s) for HEAD w/ prefix '${PUSH_TAG_PREFIX}': '$$prefixed_tags'"; \
		exit 1; \
	else \
		git tag ${PUSH_TAG_PREFIX}-$$(date +%Y-%m-%d_%H-%M-%S) && \
		git push --tags; \
	fi

.PHONY: drone-deploy
drone-deploy: DRONE_DEPLOY_ENVIRONMENT := prod
drone-deploy:  ## drone deploy latest build to prod environment
	# Get the latest drone build number if DRONE_DEPLOY_BUILD is not defined
	# and deploy DRONE_DEPLOY_BUILD to ${DRONE_DEPLOY_ENVIRONMENT}
	@if [ -z "${DRONE_DEPLOY_BUILD}" ]; then \
		DRONE_DEPLOY_BUILD=`drone build ls -limit 1 -format '{{.Number}}'  ${DRONE_REPO}` ; \
	fi; \
	drone deploy ${DRONE_REPO} $${DRONE_DEPLOY_BUILD} ${DRONE_DEPLOY_ENVIRONMENT}

## end of drone08.mk
