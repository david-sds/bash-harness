COMPOSE ?= docker compose
SHELL   := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help build up down logs ps stats models pull chat shell clean host-off

help: ## show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk -F':.*?## ' '{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

build: ## build the harness image
	$(COMPOSE) build harness

up: ## start ollama in the background
	$(COMPOSE) up -d ollama

down: ## stop and remove containers (models are on the host, they survive)
	$(COMPOSE) down

logs: ## follow ollama logs
	$(COMPOSE) logs -f ollama

ps: ## show container status, including exited ones
	$(COMPOSE) ps -a

stats: ## show cpu/mem limits in use
	docker stats --no-stream $$($(COMPOSE) ps -q)

models: ## list models visible to the container
	$(COMPOSE) exec ollama ollama list

pull: ## pull a model: make pull M=gpt-oss:20b
	@test -n "$(M)" || { echo "usage: make pull M=<model>"; exit 1; }
	$(COMPOSE) exec ollama ollama pull $(M)

chat: ## interactive harness session
	$(COMPOSE) run --rm -it harness

shell: ## bash inside the harness image, no script
	$(COMPOSE) run --rm -it --entrypoint bash harness

clean: ## remove stopped harness containers
	$(COMPOSE) rm -f harness
	docker container prune -f --filter label=com.docker.compose.project=bash-harness

host-off: ## disable the host ollama service (needs sudo)
	sudo systemctl disable --now ollama
