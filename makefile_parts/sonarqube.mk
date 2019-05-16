
################################################################################
## sonarqube.mk
# Makefile goals sonarqube scan
################################################################################

ifndef SONARQBUBE_SERVER
	export SONARQBUBE_SERVER=https://sonarqube.example.com
endif

ifndef SONARQUBE_TONKE_FILE
	export SONARQUBE_TONKE_FILE=${HOME}/.sonar-token
endif

.PHONY: sonar-sec
sonar-sec: ## check to see if $HOME/.sonar-token is set
	@if ! [ -f ${SONARQUBE_TONKE_FILE} ]; then \
		echo "${SONARQUBE_TONKE_FILE} is missing." ; \
		echo "Please generate the auth token from ${SONARQBUBE_SERVER}/account/security" ; \
		echo "and save it to ${SONARQUBE_TONKE_FILE}" ; \
		false; \
	fi

.PHONY: install-sonar-scanner
install-sonar-scanner: ## check and install 
	@install-sonar-scanner.sh

.PHONY: sonar-scan
sonar-scan: sonar-sec install-sonar-scanner ## sonarqube scan
	@sonar-scanner \
		-Dsonar.host.url=${SONARQBUBE_SERVER} \
		-Dsonar.login=$(shell cat ${HOME}/.sonar-token)

.PHONY: mvn-scan
mvn-scan: sonar-sec ## maven clean package sonar:sonar
	@mvn -s settings.xml sonar:sonar \
		-Dsonar.host.url=${SONARQBUBE_SERVER} \
		-Dsonar.login=$(shell cat ${HOME}/.sonar-token)

.PHONY: drone-sonar-confg
drone-sonar-confg: ## show sonar-scanner drone config
	@echo;echo; echo 'Add following lines in .drone.sec:'
	@cat ${FRAMEWORK_DIR}/artifacts/drone.sec.examples
	@echo; echo; echo 'Add following jobs to .drone.yml:'
	@cat ${FRAMEWORK_DIR}/artifacts/drone.yml.examples
	@echo; echo; echo 'Add following jobs to sonar-projecdt.properties:'
	@cat ${FRAMEWORK_DIR}/artifacts/sonar-projecdt.properties.examples


## end of sonarqube.mk
