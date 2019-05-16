

################################################################################
## merge-request.mk
# makefile targets to allow a merge request
################################################################################

ifndef GITLAB_URL
	missing_vars := ${missing_vars} GITLAB_URL
endif

ifndef DRONE_REPO
	missing_vars := ${missing_vars} DRONE_REPO
endif

.PHONY: merge-request
merge-request: ## create merge request to stage changes, merge to prod when changes verified
	@echo opening "${GITLAB_URL}/${DRONE_REPO}/merge_requests/new/diffs?merge_request%5Bsource_branch%5D=master&merge_request%5Btarget_branch%5D=prod" && \
		sleep 3 && \
		open "${GITLAB_URL}/${DRONE_REPO}/merge_requests/new/diffs?merge_request%5Bsource_branch%5D=master&merge_request%5Btarget_branch%5D=prod"
