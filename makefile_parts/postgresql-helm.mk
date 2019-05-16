

################################################################################
# postgres.mk
################################################################################

ifndef TEMPLATES
	missing_vars := ${missing_vars} TEMPLATES
endif

ifndef GKE_CLUSTER_NAME
	missing_vars := ${missing_vars} GKE_CLUSTER_NAME
endif

.PHONY: create-postgres-ns
create-postgres-ns: config-kube ## create cert-manager namespace
	@if ! kubectl get namespace ${POSTGRESQL_NS} &> /dev/null ; then \
		kubectl create namespace ${POSTGRESQL_NS} ; \
	fi

.PHONY: deploy-postgres
deploy-postgres: create-postgres-ns ## provisioning the postgres
	@cat ${DB_VALUES_FILE} | gomplate.sh | helm install \
		-f - \
		--name postgres \
		--namespace ${POSTGRESQL_NS} \
		stable/postgresql
	
.PHONY: update-postgres
update-postgres: config-kube # update the postgres
	@cat ${DB_VALUES_FILE} | gomplate.sh | helm upgrade \
		-f - \
		postgres stable/postgres

.PHONY: destroy-postgres
destroy-postgres: config-kube ## destroy the postgres
	@helm del --purge postgres

###########
## Test
###########
.PHONY: test-postgres
test-postgres:  ## Test postgres service
	@kubectl run -n ${POSTGRESQL_NS} postgres-postgresql-client \
		--restart=Never --rm --tty -i --image postgres \
   		--env "PGPASSWORD=$(shell kubectl get secret -n ${POSTGRESQL_NS} postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode; echo)" \
   		--command -- psql -U postgres \
   		-h postgres-postgresql postgres

## end of postgres.mk
