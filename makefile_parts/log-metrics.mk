
ifndef LOG_METRICS_DIR
	ifeq ($(wildcard ../common),)
		LOG_METRICS_DIR := gcp-config/log-metrics
	else
		LOG_METRICS_DIR := ../common/gcp-config/log-metrics
	endif
endif

ifndef MONITORING_DIR
	ifeq ($(wildcard ../common),)
		MONITORING_DIR := gcp-config/monitoring
	else
		MONITORING_DIR := ../common/gcp-config/monitoring
	endif
endif

.PHONY: log-metrics
log-metrics: config-gcloud-user ## create log metrics with ${LOG_METRICS_DIR}
	@${SCRIPTS_DIR}/log-metrics-create.sh ${LOG_METRICS_DIR} ${GCP_MONITORING_PROJECT_ID}

.PHONY: monitoring
monitoring: SLACK_CHANNEL=$(shell gcloud alpha monitoring channels list --format=json \
	| jq --arg C "#${GCP_SLACK_CHANNEL}" -r '.[] | select((.type=="slack") and (.labels.channel_name==$$C)).name')
monitoring: config-gcloud-user ## create or update alert policy
	${SCRIPTS_DIR}/alert-policy-update.sh ${MONITORING_DIR}
