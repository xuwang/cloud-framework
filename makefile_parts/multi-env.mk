

################################################################################
## multi-env.mk
# Makefile targets useful for multi environment makefiles
# e.g.: dev, stage, prod environments
################################################################################

.PHONY: only-prod
only-prod:
	@if [ ! "$$(basename $$PWD)" = "prod" ]; then \
		>&2 echo "ERROR: this command is only applicable for prod/ environment"; \
		exit 1; \
	fi

.PHONY: only-user
only-user:
@if [ ! "$$(basename $$PWD)" = "user" ]; then \
	>&2 echo "ERROR: this command is only applicable for user/ environment"; \
	exit 1; \
fi

.PHONY: only-dev
only-user:
@if [ ! "$$(basename $$PWD)" = "dev" ]; then \
	>&2 echo "ERROR: this command is only applicable for dev/ environment"; \
	exit 1; \
fi

.PHONY: not-common
not-common:
	@if [ "$$(basename $$PWD)" = "common" ]; then \
		>&2 echo "ERROR: this command is not applicable for common/ environment"; \
		exit 1; \
	fi
