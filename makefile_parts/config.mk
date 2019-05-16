
################################################################################
## config.mk
# Targets for setting up gcloud configuration
# Depends on vault.mk, {SCRIPTS_DIR}
################################################################################

ifndef GCP_CONFIGURATION
	missing_vars := ${missing_vars} GCP_CONFIGURATION
endif

ifndef GCP_PROJECT_ID
	missing_vars := ${missing_vars} GCP_PROJECT_ID
endif

.PHONY: config
config: config-kube ## alias for config-kube

# Always do config!
#-include config

.PHONY: config-gcloud
config-gcloud: ## config gcloud and setup auth
	@if [ "$(MAKELEVEL)" -eq "0" ]; then \
		${SCRIPTS_DIR}/config.sh ; \
	fi

.PHONY: revoke-gcloud 
revoke-gcloud: ## revoke just gcloud credentials
	@gcloud auth revoke --all --quiet || true
	@rm -f ${HOME}/.config/gcloud/application_default_credentials.json

.PHONY: config-info
config-info: ## list gcloud config values
	@gcloud config list

.PHONY: config-kube
config-kube: config-gcloud ## config kubectl and setup kubectl auth
	@if [ "$(MAKELEVEL)" -eq "0" ]; then \
		${SCRIPTS_DIR}/config-kube.sh ; \
	fi

.PHONY: config-app-default
config-app-default: ## Set application-default-credentials with personal credentials...
	@if [ "$(MAKELEVEL)" -eq "0" ]; then \
		echo "Set application-default-credentials with personal credentials..."; \
    	gcloud auth application-default login ; \
	fi

.PHONY: revoke-kube
revoke-kube: ## revoke current kubernetes context
	@CTX=$$(kubectl config current-context) ; \
	if ! [ -z $$CTX ]; then \
      kubectl config delete-context $$CTX || true; \
    fi
#	@rm -f ~/.kube/config

.PHONY: revoke-kube-message
revoke-kube-message:
	@echo Revoking prior kubernetes credentials before obtaining new ones

# no prereq for GCP_KEY_FILE since it is user login flow
.PHONY: config-gcloud-user
config-gcloud-user: GKE_USER_AUTH=true 
config-gcloud-user: ## config gcloud and setup auth by using user oauth
	@${SCRIPTS_DIR}/config.sh

.PHONY: config-kube-user
config-kube-user: config-gcloud-user ## config kubectl and setup auth by using user oauth
	@${SCRIPTS_DIR}/config-kube.sh

.PHONY: revoke
revoke: ## revoke gcloud and gke credentials
	@$(MAKE) revoke-gcloud
	@$(MAKE) revoke-kube

.PHONY: cluster-info
cluster-info: ## show GKE cluster info
	@kubectl cluster-info
	@kubectl get all --all-namespaces

## end of config.mk
