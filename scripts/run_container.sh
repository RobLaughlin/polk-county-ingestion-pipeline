#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_DIR/compose.yaml"

if [ -n "$(docker compose -f "$COMPOSE_FILE" ps --status running -q ingest)" ]; then
    echo "Ingestion container already running."
    exit 0
fi

# The container reads the project ID from its environment (see compose.yaml).
GOOGLE_CLOUD_PROJECT=$(terraform -chdir="$PROJECT_DIR/terraform" output -raw gcp_project_id)
export GOOGLE_CLOUD_PROJECT

# Building is left to build_image.sh, so never build or pull here.
docker compose -f "$COMPOSE_FILE" up -d --no-build --pull never ingest
