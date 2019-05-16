# makefile to setup stackdriver log metrics and monitoring alerts
# TODO: should be moved to terraform when tf google provider is ready

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

ifndef ALERTS_DIR
	ifeq ($(wildcard ../common),)
		 ALERTS_DIR := gcp-config/alerts
	else
		ALERTS_DIR := ../common/gcp-config/alerts
	endif
endif

.PHONY: create-log-metrics
log-metrics: config-gcloud-user ## create log metrics with ${LOG_METRICS_DIR}
	@${SCRIPTS_DIR}/log-metrics-create.sh ${LOG_METRICS_DIR} ${GCP_MONITORING_PROJECT_ID}

.PHONY: create-alerts
create-alerts: SLACK_CHANNEL=$(shell gcloud alpha monitoring channels list --format=json \
	| jq --arg C "#${GCP_SLACK_CHANNEL}" -r '.[] | select((.type=="slack") and (.labels.channel_name==$$C)).name')
create-alerts: config-gcloud-user ## create or replace alert policies in ${ALERTS_DIR}
	${SCRIPTS_DIR}/alert-policy-create.sh ${ALERTS_DIR}

.PHONY: update-alerts
update-alerts: SLACK_CHANNEL=$(shell gcloud alpha monitoring channels list --format=json \
	| jq --arg C "#${GCP_SLACK_CHANNEL}" -r '.[] | select((.type=="slack") and (.labels.channel_name==$$C)).name')
update-alerts: config-gcloud-user ## update or create alert policies in ${ALERTS_DIR}
	${SCRIPTS_DIR}/alert-policy-update.sh ${ALERTS_DIR}
