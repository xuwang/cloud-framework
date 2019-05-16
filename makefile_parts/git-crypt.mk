

################################################################################
# DEPRECATED
# git-crypt.mk
################################################################################

# Targets for lock and unlock git-crypt protected repos, defined in GIT_CRYPT_REPOS
.PHONY: unlock
unlock: ## unlock the git-crypt protected repos, i.e. decrypt  all secretes
	@for dir in ${GIT_CRYPT_REPOS}; do \
		( cd $$dir; \
		  if [ ! -f .git/git-crypt/keys/default ]; \
		  then \
			echo unlocking $$dir; \
			git-crypt unlock; \
		  else \
			echo $$dir already unlocked; \
		  fi; \
		 ); \
	done
.PHONY: unlock
lock: ## lock up the git-crypt protected repos, i.e. encrypt all secretes
	@for dir in ${GIT_CRYPT_REPOS}; do \
		( echo locking $$dir; cd $$dir; git-crypt lock; echo locked: $$dir;  ); \
	done
