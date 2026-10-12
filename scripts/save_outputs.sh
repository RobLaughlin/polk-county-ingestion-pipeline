#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
INGESTION_DIR="$SCRIPT_DIR/../ingestion/"

terraform -chdir="$INGESTION_DIR/../terraform" output -json > "$INGESTION_DIR/outputs.json"