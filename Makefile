IMAGE=hypefactors/docker-ci:latest

.DEFAULT_GOAL := help

build: ## Build the docker image
	docker build -t hypefactors/docker-ci:latest .
	docker history $(IMAGE) > build_log.txt
tests: ## Run the unit tests
	./test/run.sh

help: ## Display this help message
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.SILENT: build test help