THIS_MAKEFILE := $(realpath $(lastword $(MAKEFILE_LIST)))
PATH := ${SCRIPTS_DIR}:${PATH}
include env.mk
export

# FRAMEWORK SYNC
ifeq ($(MAKELEVEL),0)
    _ := $(shell >&2 echo)
	ifneq ($(wildcard ${FRAMEWORK_DIR}/.git/),)
		_ := $(shell >&2 echo Updating  cloud framework from Git into ${FRAMEWORK_DIR}...)
		_ := $(shell cd ${FRAMEWORK_DIR}; git pull)
	else
		_ := $(shell >&2 echo Updating cloud framework in ${FRAMEWORK_DIR}...)
		_ := $(shell mkdir -p ${FRAMEWORK_DIR} && curl --retry 3 -s https://storage.googleapis.com/${FRAMEWORK_BUCKET}/framework.tar.gz?random=$$(date +%s) | tar -xzf - -C ${FRAMEWORK_DIR})
		_ := $(shell >&2 echo - framework version: $$(cat ${FRAMEWORK_DIR}/sha.txt))
	endif
endif
# END FRAMEWORK SYNC

# COMMON MAKEFILE PARTS INCLUDES
include ${FRAMEWORK_DIR}/makefile_parts/shared.mk
include ${FRAMEWORK_DIR}/makefile_parts/config.mk
include ${FRAMEWORK_DIR}/makefile_parts/terraform.mk
include ${FRAMEWORK_DIR}/makefile_parts/stackdriver.mk
include ${FRAMEWORK_DIR}/makefile_parts/vault.mk
include ${FRAMEWORK_DIR}/makefile_parts/sub-projects.mk
include ${FRAMEWORK_DIR}/makefile_parts/deps.mk
# END COMMON MAKEFILE PARTS INCLUDES

# needed for writing secrets to vault
tf-apply: vault-login

tf-destroy: vault-login
	@echo Do NOT destroy the produciton setup.

.PHONY: test-bastion
test-bastion: BASTION=$(shell gcloud compute instances list --filter name:${GCP_VPC_NAME}-bastion --uri --limit=1)
test-bastion: TEST_NAT_CMD="curl -s https://ipconfig.io/ip"
test-bastion: config ## test NAT gateway's connectivity
	@for i in ${BASTION}; do \
		echo; echo "Bastion Host IP:"; \
		gcloud compute ssh $${i} --command=${TEST_NAT_CMD}; \
	done

.PHONY: ssh-bastion
ssh-bastion: BASTION=$(shell gcloud compute instances list --filter name:${GCP_VPC_NAME}-bastion --uri --limit=1)
ssh-bastion: config ## ssh to a nat-gateway-1, 'evel ssh-agent' is required.
	@if [ ! -f ${HOME}/.ssh/google_compute_engine ]; then \
		echo "Press return for empty passphrase." ; \
		echo "" ; \
		gcloud compute ssh ${BASTION} --command uptime ; \
	fi
	ssh-add ${HOME}/.ssh/google_compute_engine
	gcloud compute ssh ${BASTION}

${HOME}/bin/cloud_sql_proxy: UNAME=$(shell uname | tr '[:upper:]' '[:lower:]')
${HOME}/bin/cloud_sql_proxy:  ## install cloud_sql_proxy, ONLY tested for MacOS!!!
	curl -o ${HOME}/bin/cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.${UNAME}.amd64
	chmod 755 ${HOME}/bin/cloud_sql_proxy

.PHONY: mysql-proxy
mysql-proxy: CONNECTION_NAME=$(shell gcloud sql instances describe mysql-prod-${GCP_REGION}-master --format json | jq -r ".connectionName")
mysql-proxy: ${HOME}/bin/cloud_sql_proxy #config ## proxy to cloud-sql/mysql
	cloud_sql_proxy -instances=${CONNECTION_NAME}=tcp:3306

.PHONY: postgres-proxy
postgres-proxy: CONNECTION_NAME=$(shell gcloud sql instances describe postgres-prod-${GCP_REGION} --format json | jq -r ".connectionName")
postgres-proxy: ${HOME}/bin/cloud_sql_proxy #config ## proxy to cloud-sql/postgres
	cloud_sql_proxy -instances=${CONNECTION_NAME}=tcp:5432

.PHONY: postgres-medwiki-proxy
postgres-medwiki-proxy: CONNECTION_NAME=$(shell gcloud sql instances describe postgres-medwiki-prod-${GCP_REGION} --format json | jq -r ".connectionName")
postgres-medwiki-proxy: ${HOME}/bin/cloud_sql_proxy #config ## proxy to cloud-sql/postgres
	cloud_sql_proxy -instances=${CONNECTION_NAME}=tcp:5432

.PHONY: save-env
save-env: vault-login ## save env.mk to vault:/<SEC_PATH>/common/env.mk
	vault-write.sh ${SEC_PATH}/common/env.mk @env.mk
