#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_DIR/compose.yaml"

IMAGE=$(docker compose -f "$COMPOSE_FILE" config --images)

if docker image inspect "$IMAGE" > /dev/null 2>&1; then
    echo "Image $IMAGE already built."
    exit 0
fi

docker compose -f "$COMPOSE_FILE" build ingest
