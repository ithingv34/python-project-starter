# Makefile
.DEFAULT_GOAL := help
.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


# Import Environment
include .env

##@ Formatters

format-black: ## run black (code formatter)
	@black .

format-isort: ## run isort (imports formatter)
	@isort .

format: format-black format-isort ## run all formatters

##@ Linters

lint-black: ## run black in linting mode
	@black . --check

lint-isort: ## run isort in linting mode
	@isort . --check

lint-flake8: ## run flake8 (code linter)
	@flake8 .

lint-mypy: ## run mypy (static-type checker)
	@mypy .

lint-mypy-report: # run mypy & create report
	@mypy ./src --html-report ./mypy_html

lint: lint-black lint-isort lint-flake8 lint-mypy ## run all linters

unit-tests:
	@pytest --doctest-modules
unit-tests-cov:
	@pytest --doctest-modules --cache-clear --cov=src --cov-report term-missing --cov-report=html
unit-tests-cov-fail:
	@pytest --doctest-modules --cache-clear --cov=src --cov-report term-missing --cov-report=html --cov-fail-under=80 --junitxml=pytest.xml | tee pytest-coverage.txt
clean-cov:
	@rm -rf .coverage
	@rm -rf htmlcov
	@rm -rf pytest.xml
	@rm -rf pytest-coverage.txt


##@ Documentation
docs-build: create_openapi ## build documentation locally
	@mkdocs build

create_openapi: ## create openapi.json
	@python3 scripts/create_openapi_json.py

docs-deploy: ## build & deploy documentation to "gh-pages" branch
	@mkdocs gh-deploy -m "docs: update documentation" -v --force

clean-docs: ## remove output files from mkdocs
	@rm -rf site

##@ Releases

current-version: ## returns the current version
	@semantic-release print-version --current

next-version: ## returns the next version
	@semantic-release print-version --next

current-changelog: ## returns the current changelog
	@semantic-release changelog --released

next-changelog: ## returns the next changelog
	@semantic-release changelog --unreleased

publish-noop: ## publish command (no-operation mode)
	@semantic-release publish --noop

# Container Build

build: ## docker build
	@docker build --file Dockerfile --tag $(DOCKER_IMAGE_NAME):latest --target production .

run: ## docker run app
	@docker run -p $(APP_PORT):80 -it --rm project:latest

run-bash: ## docker run with bash
	@docker run -it --rm $(DOCKER_IMAGE_NAME):latest /bin/bash

login: ## login to ghcr.io using a personal access token (PAT)
	@if [ -z "$(CR_PAT)" ]; then\
		echo "Personal Access Token for Ghcr is not set";\
	else\
		echo $(CR_PAT) | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin;\
	fi

tag: ## tag docker image to ghcr.io/johschmidt42/project:latest
	@docker tag $(DOCKER_IMAGE_NAME):latest ghcr.io/${GITHUB_USERNAME}/$(DOCKER_IMAGE_NAME):latest

push: tag ## docker push to container registry (ghcr.io)
	@docker push ghcr.io/${GITHUB_USERNAME}/$(DOCKER_IMAGE_NAME):latest