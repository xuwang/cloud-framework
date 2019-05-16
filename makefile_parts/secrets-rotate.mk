ifndef GCP_PROJECT_ID
	_ := $(error var GCP_PROJECT_ID not set)
endif

ifndef SECRETS_ROTATE_FILE
	SECRETS_ROTATE_FILE := ${COMMON}/secrets-rotate.yaml
endif

.PHONY: secrets-generate
secrets-generate: vault-login config-gcloud ## generate secrets defined in ${SECRETS_ROTATE_FILE}
	@${SCRIPTS_DIR}/secrets-rotate.sh ${SECRETS_ROTATE_FILE} generate

.PHONY: secrets-rotate
secrets-rotate: vault-login config-gcloud ## rotate secrets defined in ${SECRETS_ROTATE_FILE}
	@${SCRIPTS_DIR}/secrets-rotate.sh ${SECRETS_ROTATE_FILE} rotate

.PHONY: secrets-cleanup
secrets-cleanup: vault-login config-gcloud ## cleans up active credentials (after rotation) if cleanupScript is set (like deleting the previous sql user used by the app)
	@${SCRIPTS_DIR}/secrets-rotate.sh ${SECRETS_ROTATE_FILE} cleanup