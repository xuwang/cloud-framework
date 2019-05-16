

################################################################################
## shared.mk
################################################################################

# set shell options, debug variable allows debugging of makefile
ifeq ($(debug),true)
	SHELL := /bin/bash -e -O extglob -O nullglob -o pipefail -x
else
	SHELL := /bin/bash -e -O extglob -O nullglob -o pipefail
endif

# set SCRIPTS_DIR if not set
ifndef SCRIPTS_DIR
	SCRIPTS_DIR=${FRAMEWORK_DIR}/scripts
endif

# add scripts to PATH
PATH := ${SCRIPTS_DIR}:${PATH}

ifneq ($(missing_vars),)
	_ := $(info )
	_ := $(info missing env var(s):)
	_ := $(info )
	_ := $(info ${missing_vars}))
	_ := $(info )
	_ := $(info you must populate the required env vars before continuing)
	_ := $(info )
	_ := $(error )
endif

function_reverse = $(if $(1),$(call function_reverse,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))

all: help

.PHONY: help
help: ## show this help page
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo
	@printf '¯\_(ツ)_/¯ \e[1;35m%-6s\e[m ¯\_(ツ)_/¯\n' "MAKEFILE TARGETS FOR DIRECTORY: $$(basename $$PWD)/"
	@#for f in ${MAKEFILE_LIST} 
	@for f in $(call function_reverse,$(MAKEFILE_LIST)); do \
		 if [ -f $$f ] && grep -qE '^[a-zA-Z_-]+:.*?## .*$$' $$f; then \
		 	echo; \
		 	simple_path="$${f/$$HOME/~}"; \
			echo '-------------------------------------------------------------------------------'; \
			printf '\e[1;32m%-6s\e[m' "$$(basename $$f)"; \
			echo " ($$simple_path)"; \
			echo '-------------------------------------------------------------------------------'; \
			cat $$f | grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' || true; \
		fi; \
	done
	@make check-tools no_pull=true

.PHONY: show-makefile
show-makefile: ## show complete makefile w/ includes
	@cat $(MAKEFILE_LIST)

.PHONY: check-tools
check-tools: ## check if required tools are installed and accessible
	@for t in gcloud kubectl vault drone jq envsubst gomplate; do \
		if ! type $$t > /dev/null 2>&1; then \
			echo ERROR: $$t command not found; \
		fi \
	done

.PHONY: show-env
show-env: ## show all env var values
	env
