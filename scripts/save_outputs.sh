#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR="$SCRIPT_DIR/.."

# Finish the Terraform command successfully before replacing any exported files.
OUTPUTS_JSON=$(terraform -chdir="$PROJECT_DIR/terraform" output -json)
printf '%s\n' "$OUTPUTS_JSON" | python3 "$SCRIPT_DIR/render_outputs.py" "$PROJECT_DIR"
