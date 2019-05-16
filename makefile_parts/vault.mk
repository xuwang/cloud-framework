

################################################################################
## vault.mk
# Targets for interacting with vault
################################################################################

ifndef VAULT_ADDR
	export VAULT_ADDR=https://vault.example.com
endif

VAULT_VERSION=v0.10.3

# OPTIONAL: VAULT_AUTH_PATH, VAULT_AUTH_METHOD

# target for checking if thim file is included
vault-mk:
	true

check-vault:
	@if [ "$$(vault version | awk '{print $$2}')" \< "${VAULT_VERSION}" ]; then \
		>&2 echo; \
		>&2 echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!; \
		>&2 echo "WARNING: you need to install vault ${VAULT_VERSION}! Run \`make deps\` (if available in this project), or else install from https://vaultproject.io"; \
		>&2 echo "- non-backwards compatible APIs will be enabled soon in the scripts"; \
		>&2 echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!; \
		>&2 echo; \
	fi

.PHONY: vault-login
vault-login: ## vault login
	@${SCRIPTS_DIR}/vault-login.sh

# Always do vault auth
# -include vault-login

# Targets for vault ops
.PHONY: vault-info
vault-info:  ## show vault info
	@${SCRIPTS_DIR}/vault-info.sh

.PHONY: vault-logout
vault-logout:  ## vault logout
	@${SCRIPTS_DIR}/vault-logout.sh

.PHONY: vault-token-audit
vault-token-audit:  ## get vault token inventory
	@${SCRIPTS_DIR}/vault-token-inventory.sh

.PHONY: vault-cap
vault-cap: path=${SEC_PATH}
vault-cap: vault-login ## list capabilities for the local token on path=<sec path>
	vault token capabilities ${path}

.PHONY: vault-revoke ## revoke vault auth token
vault-revoke: vault-logout

.PHONY: vault-help
vault-help: ## useful vault cmds
	@echo 'list secret mounts: 		vault secrets list'
	@echo 'show ldap config: 		vault read auth/ldap/config'
	@echo 'search workgroup: 		vault list auth/ldap/groups | grep <regex>'
	@echo 'show workgroup policies:	vault read auth/ldap/groups <wg_name>'
	@echo 'show policy: 			vault policy read <policy>'

.PHONY: help-approle
help-approle: ## useful vault approle cmds
	@echo "List approles ids:		vault list auth/approle/role"
	@echo "Get config of approle id:	vault read auth/approle/role/<role_id>"
	@echo "Create a secret-id:		vault write -f auth/approle/role/<role_id>/secret-id"
	@echo "Lookup a secret-id:		vault write auth/approle/role/<role_id>/secret-id/lookup secret_id=<id>"
	@echo "List secret-id accessors:	vault list auth/approle/role/<role_id>/secret-id"
	@echo "Lookup a secret-id accessor:	vault write auth/approle/role/<role_id>/secret-id-accessor/lookup secret_id_accessor=<id>"
	@echo "Destroy a secret-id by accessor: vault write auth/approle/role/<role_id>/secret-id-accessor/destroy secret_id_accessor=<id>"
	@echo 'Approle auth: 			vault write auth/approle/login role_id="<role_id>" secret_id="<secret_id>"'
	@echo 'API reference: 			https://www.vaultproject.io/api/auth/approle/index.html'