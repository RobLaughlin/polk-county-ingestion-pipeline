#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR="$SCRIPT_DIR/.."

"$SCRIPT_DIR"/save_outputs.sh
"$SCRIPT_DIR"/build_image.sh
"$SCRIPT_DIR"/run_container.sh

docker compose -f "$PROJECT_DIR/compose.yaml" exec -T ingest uv run --locked python ingest.py
