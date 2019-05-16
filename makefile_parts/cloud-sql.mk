

################################################################################
## cloud-sql.mk
################################################################################

#################
# required vars
ifndef GCP_REGION
	missing_vars := ${missing_vars} GCP_REGION
endif

ifndef GCP_ZONE
	missing_vars := ${missing_vars} GCP_ZONE
endif

# due to naming collisions of already deleted Cloud SQL databases, we must
# use mutually exclusive prefixes, and use these to look up the actual instances
# this allows us to create and destroy instances readily
ifndef CLOUD_SQL_INSTANCE_PREFIX
	missing_vars := ${missing_vars} CLOUD_SQL_INSTANCE_PREFIX
endif

ifndef CLOUD_SQL_DB_NAME
	missing_vars := ${missing_vars} CLOUD_SQL_DB_NAME
endif

ifndef CLOUD_SQL_USER_VAULT_PATH
	missing_vars := ${missing_vars} CLOUD_SQL_USER_VAULT_PATH
endif

ifndef CLOUD_SQL_ROOT_PASSWORD_VAULT_PATH
	missing_vars := ${missing_vars} CLOUD_SQL_ROOT_PASSWORD_VAULT_PATH
endif

ifndef CLOUD_SQL_USER_VAULT_PATH
	missing_vars := ${missing_vars} CLOUD_SQL_USER_VAULT_PATH
endif

# MySQL (Or postgres?) version
ifndef CLOUD_SQL_DB_VERSION
	missing_vars := ${missing_vars} CLOUD_SQL_DB_VERSION
endif

#################
# optional vars
ifndef CLOUD_SQL_TIER
	CLOUD_SQL_TIER := db-n1-standard-1
endif

ifndef CLOUD_SQL_SIZE
	CLOUD_SQL_SIZE := 10GB
endif

ifndef CLOUD_SQL_REGION
	CLOUD_SQL_REGION := ${GCP_REGION}
endif

ifndef CLOUD_SQL_ZONE
	CLOUD_SQL_ZONE := ${GCP_ZONE}
endif
# DB_FAILOVER_* parameters are also optional, default is no failover

.PHONY: cloud-sql
cloud-sql-create: vault-login config-gcloud ## create cloud SQL DB
	@db_user_password=$$(vault-read.sh ${CLOUD_SQL_USER_PASSWORD_VAULT_PATH}) && \
		db_root_password=$$(vault-read.sh ${CLOUD_SQL_ROOT_PASSWORD_VAULT_PATH}) && \
		db_user=$$(vault-read.sh ${CLOUD_SQL_USER_VAULT_PATH}) && \
		export db_user_password db_user db_root_password && \
		db_instance_prefix=${CLOUD_SQL_INSTANCE_PREFIX} \
		db_version=${CLOUD_SQL_DB_VERSION} \
		db_name=${CLOUD_SQL_DB_NAME} \
		db_zone=${CLOUD_SQL_ZONE} \
		db_region=${CLOUD_SQL_REGION} \
		db_tier=${CLOUD_SQL_TIER} \
		db_size=${CLOUD_SQL_SIZE} \
		db_failover_instance_prefix=${CLOUD_SQL_FAILOVER_INSTANCE_PREFIX} \
		db_failover_zone=${CLOUD_SQL_FAILOVER_ZONE} \
		db_failover_tier=${CLOUD_SQL_FAILOVER_TIER} \
		cloud-sql-create.sh

.PHONY: cloud-sql-delete
cloud-sql-delete: config-gcloud ## destroy cloud SQL DB
	@db_instance_prefix=${CLOUD_SQL_INSTANCE_PREFIX} \
		db_failover_instance_prefix=${CLOUD_SQL_FAILOVER_INSTANCE_PREFIX} \
		cloud-sql-delete.sh

.PHONY: cloud-sql-snapshot
cloud-sql-snapshot: config-gcloud ## snapshot cloud SQL DB
	@db_instance_prefix=${CLOUD_SQL_INSTANCE_PREFIX} \
		db_snapshot_description='pre-upgrade snapshot' \
		cloud-sql-snapshot.sh 

.PHONY: cloud-sql-rollback
cloud-sql-rollback: config-gcloud ## rollback cloud SQL DB to latest snapshot
	@db_instance_prefix=${CLOUD_SQL_INSTANCE_PREFIX} \
		db_version=${CLOUD_SQL_DB_VERSION} \
		db_zone=${CLOUD_SQL_ZONE} \
		db_region=${CLOUD_SQL_REGION} \
		db_tier=${CLOUD_SQL_TIER} \
		db_size=${CLOUD_SQL_SIZE} \
		db_failover_instance_prefix=${CLOUD_SQL_FAILOVER_INSTANCE_PREFIX} \
		db_failover_zone=${CLOUD_SQL_FAILOVER_ZONE} \
		db_failover_tier=${CLOUD_SQL_FAILOVER_TIER} \
		cloud-sql-rollback.sh

