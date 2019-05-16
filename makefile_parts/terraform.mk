####################################
# Terraform makefile targets
####################################

ifndef GCP_INFRASTRUCTURE_BUCKET
	GCP_INFRASTRUCTURE_BUCKET=${GCP_PROJECT_ID}-infrastructure
endif

# Required by terraform google providor
ifndef REQUIRE_APPLICATION_DEFAULT_CREDENTIALS
	REQUIRE_APPLICATION_DEFAULT_CREDENTIALS := true
endif

# set Terraform envs defaults
ifndef TF_CMD
	TF_CMD := terraform
endif

ifndef TF_DIR
	TF_DIR := terraform
endif

ifndef TF_MODULES_DIR
	TF_MODULES_DIR := terraform-modules
endif

ifndef TF_BUILD_DIR
	TF_BUILD_DIR := build
endif

export

.PHONY: tf-setup
tf-setup: config-gcloud ## create terraform remote state bucket if not exists
	@if ! gsutil ls -p ${GCP_PROJECT_ID} gs://${GCP_INFRASTRUCTURE_BUCKET} &> /dev/null; \
	then \
		echo creating gs://${GCP_INFRASTRUCTURE_BUCKET} ... ; \
		gsutil mb -p ${GCP_PROJECT_ID} gs://${GCP_INFRASTRUCTURE_BUCKET}; \
		sleep 20 ; \
	fi

.PHONY: tf-init
tf-init: tf-setup ## terraform init
	@if [ "$(MAKELEVEL)" -eq "0" ]; then \
		${SCRIPTS_DIR}/tf-init.sh ; \
	fi

.PHONY: tf-validate
tf-validate: tf-init ## validate syntax of the terraform files
	cd ${TF_BUILD_DIR}; ${TF_CMD} validate

.PHONY: tf-plan
tf-plan: tf-init ## terraform plan
	cd ${TF_BUILD_DIR}; ${TF_CMD} plan

.PHONY: tf-apply
tf-apply: tf-init  ## terraform apply
	cd ${TF_BUILD_DIR}; ${TF_CMD} apply -refresh=true ${tf_opt}

.PHONY: tf-destroy
tf-destroy: tf-init ## terraform destroy
	cd ${TF_BUILD_DIR}; \
	${TF_CMD} destroy -refresh=true ${tf_opt}

.PHONY: tf-show
tf-show: tf-init ## terraform show
	cd ${TF_BUILD_DIR}; ${TF_CMD} show

.PHONY: tf-get
tf-get: tf-init ## terraform get
	cd ${TF_BUILD_DIR}; ${TF_CMD} get

.PHONY: tf-refresh
tf-refresh: tf-init ## terraform refresh
	cd ${TF_BUILD_DIR}; ${TF_CMD} refresh

.PHONY: tf-output
tf-output: tf-init ## terraform output
	cd ${TF_BUILD_DIR}; ${TF_CMD} output

.PHONY: tf-output-json
tf-output-json: tf-init ## terraform output in json format
	cd ${TF_BUILD_DIR}; ${TF_CMD} output -json

.PHONY: tf-clean
tf-clean: ## remove the build dir
	rm -rf ${TF_BUILD_DIR}