#!/usr/bin/env bash

export AGENT_PORT=$(curl --silent https://raw.githubusercontent.com/TidyBee/tidybee-agent/79-improve-the-agents-dockerfile-and-add-docs-on-how-to-run-it/config/default.json | \
jq --raw-output .http_server_config.port)
[ $AGENT_PORT ] || exit 1
docker compose --file docker-compose.yml up --detach
