
ifndef LOG_SINKS_DIR
	ifeq ($(wildcard ../common),)
		LOG_SINKS_DIR := gcp-config/log-sinks
	else
		LOG_SINKS_DIR := ../common/gcp-config/log-sinks
	endif
endif

.PHONY: log-sinks-create
log-sinks: config-gcloud-user ## create log sinks based on ${LOG_SINKS_FILE}
	@${SCRIPTS_DIR}/log-sinks-create.sh ${LOG_SINKS_DIR} ${GCP_MONITORING_PROJECT_ID}