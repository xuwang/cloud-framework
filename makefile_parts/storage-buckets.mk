
ifndef STORAGE_BUCKETS_DIR
	ifeq ($(wildcard ../common),)
		STORAGE_BUCKETS_DIR := gcp-config/storage-buckets
	else
		STORAGE_BUCKETS_DIR := ../common/gcp-config/storage-buckets
	endif
endif

.PHONY: storage-buckets
storage-buckets: config-gcloud-user ## create storage buckets and set iam privileges with files in ${STORAGE_BUCKETS_DIR}
	@${SCRIPTS_DIR}/storage-buckets-create.sh ${STORAGE_BUCKETS_DIR}