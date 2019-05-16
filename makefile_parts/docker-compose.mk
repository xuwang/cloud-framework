

################################################################################
## docker-compose.mk
# Targets for docker-compose ops
# Depends on vault.mk
################################################################################

ifndef DOCKER_NAMESPACE
	DOCKER_NAMESPACE=${GCP_PROJECT_ID}
endif

ifndef COMPOSE_FILE
	COMPOSE_FILE := docker-compose.yml
endif

.PHONY: docker-composer-init
docker-composer-init:
	@if [ -z ${DOCKER_REGISTRY} ]; then \
		echo DOCKER_REGISTRY is not defined ; \
		false; \
	fi
	@if [ -z ${DOCKER_IMAGE} ]; then \
		echo DOCKER_IMAGE is not defined ; \
		false; \
	fi
	@if [ -z ${DOCKER_NAMESPACE} ]; then \
		echo DOCKER_NAMESPACE is not defined ; \
		false; \
	fi
	@if [ -z ${DOCKER_REGISTRY_USERNAME} ]; then \
		echo DOCKER_REGISTRY_USERNAME is not defined ; \
		false; \
	fi
	@if [ -z ${DOCKER_REGISTRY_PASSWORD_PATH} ]; then \
		echo DOCKER_REGISTRY_USERNAME is not defined ; \
		false; \
	fi

.PHONY: build-docker
build-docker: docker-composer-init ## build docker image
	@if  [ -f Dockerfile ]; then \
		docker build --pull -t ${DOCKER_IMAGE}:latest . ; \
	elif [ -f ${COMPOSE_FILE} ]; then \
		docker-compose -f ${COMPOSE_FILE} build --pull; \
	fi

.PHONY: app-up
app-up: ## docker-compose up, run in the backgroud
	@if [ -f  ${COMPOSE_FILE} ]; then \
		docker-compose -f ${COMPOSE_FILE} up -d ; \
	else \
		echo No ${COMPOSE_FILE} file! ; \
	fi

.PHONY: app-down
app-down: ## docker-compose down
	@if [ -f  ${COMPOSE_FILE} ]; then \
		docker-compose -f ${COMPOSE_FILE} down --remove-orphans ; \
	else \
		echo No ${COMPOSE_FILE} file! ; \
	fi
	

.PHONY: app-logs
app-logs: ## follow the all logs
	@if [ -f  ${COMPOSE_FILE} ]; then \
		docker-compose -f ${COMPOSE_FILE} logs -f ; \
	else \
		echo No ${COMPOSE_FILE} file! ; \
	fi
		
.PHONY: prune
prune: ## prune local docker containers and images
	docker container prune
	docker images prune

.PHONY: docker-login
docker-login: docker-composer-init ## login to private docker registry
	@if [ -z ${DOCKER_REGISTRY_PASSWORD_PATH} ]; then \
		gcloud auth configure-docker; \
		docker login https://${DOCKER_REGISTRY}; \
	else \
		make vault-login; \
		vault-read.sh ${DOCKER_REGISTRY_PASSWORD_PATH} \
			| docker login -u "${DOCKER_REGISTRY_USERNAME}" --password-stdin https://${DOCKER_REGISTRY} ;\
	fi

.PHONY: push-version
push-version: docker-login ## tag image with DOCKER_IMAGE_VERSION or git commit sha if DOCKER_IMAGE_VERSION is not given and push the image to project's docker registry
	@if [ -z ${DOCKER_IMAGE_VERSION} ]; then \
		IMAGE_TAG=${DOCKER_IMAGE}:`git rev-parse --verify HEAD` ; \
	else \
		IMAGE_TAG=${DOCKER_IMAGE}:${DOCKER_IMAGE_VERSION} ; \
	fi; \
	docker tag ${DOCKER_IMAGE}:latest ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/$$IMAGE_TAG ; \
	echo Push ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/$$IMAGE_TAG ... ; \
	docker push ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/$$IMAGE_TAG

.PHONY: push-latest
push-latest: docker-login ## tag latest image and push to project's docker registry
	@IMAGE_TAG=${DOCKER_IMAGE}:latest; \
	docker tag ${DOCKER_IMAGE}:latest ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/$$IMAGE_TAG ; \
	echo Push ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/$$IMAGE_TAG ... ; \
	docker push ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/$$IMAGE_TAG

.PHONY: pull-latest
pull-latest: docker-login ## pull latest image from project's docker registry
	docker pull ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:latest

.PHONY: pull-version
pull-version: docker-login ## pull image version from project's docker registry
	docker pull ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_IMAGE_VERSION}


list-mirror: ## list mirrored library images
	gcloud container images list --repository=mirror.gcr.io/library

## end of docker-compose.mk
