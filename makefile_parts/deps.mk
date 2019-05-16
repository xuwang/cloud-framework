
################################################################################
## deps.mk
# Targets for fetching required binaries, CLI utilities
################################################################################

ifndef DEPS_DIR
	DEPS_DIR=${HOME}/bin
endif
PATH := ${DEPS_DIR}:${PATH}:${HOME}/bin/cf-binaries

.PHONY: deps-install
deps-install: ## fetch and install all required dependencies to ${DEPS_DIR}
	@echo
	@echo Dependencies directory: ${DEPS_DIR}
	@echo
	@${SCRIPTS_DIR}/fetch-dependencies.sh

.PHONY: deps
deps-check: ## check all required dependencies
	@echo
	@echo Dependencies directory: ${DEPS_DIR}
	
	@echo
	@${SCRIPTS_DIR}/fetch-dependencies.sh check

.PHONY: test
test-cmd: ## utility function to try a command with context of makefile, (e.g. make test-cmd cmd='helm version')
	${cmd}
