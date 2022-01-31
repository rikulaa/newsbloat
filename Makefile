.MAIN: help

help:           ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: dev
dev: ## Start development (boots up db and elixir processes)
	./.bin/dev.sh

# production:
# 	./.bin/production.sh

.PHONY: initialize
initialize: ## Initializes development environmnet
	./.bin/initialize.sh
