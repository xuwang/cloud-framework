

################################################################################
## sub-projects.mk
################################################################################


ifndef SUB_PROJECTS
	missing_vars := ${missing_vars} SUB_PROJECTS
endif

# Targets for managing sub-projects
.PHONY: clone-repos
clone-repos: update-repos ## clone all related repos into sub-projeccts

.PHONY: update-repos
update-repos: repos.txt ## update all related repos in sub-projects
	git pull
	${SCRIPTS_DIR}/update-repos.sh repos.txt

.PHONY: sync-env
sync-env: repos.txt update-repos ## sync env.mk to sub-project's gcp-env.mk
	git pull
	${SCRIPTS_DIR}/sync-gcp-env.mk repos.txt

.PHONY: repos-status
repos-status:  ## check status of the related repos
	git pull
	@cd ${SUB_PROJECTS} ; \
	for dir in `ls`; do \
		if [ -d $$dir ]; \
		then \
			echo Check git status $$dir; \
			cd $$dir; git status; cd ..; \
		fi; \
	done

.PHONY: clean-repos
clean-repos: ## remove all local clone of related repos in sub-projects
	@read -p "This will delete all the local repos, are you sure? [YES/NO] " ; \
	if [ "$$REPLY" = "YES" ] ; \
	then \
		echo "rm -rf ${SUB_PROJECTS}" ; \
		rm -rf ${SUB_PROJECTS} ; \
	else \
		echo "do nothing" ; \
	fi

