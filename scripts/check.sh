#!/usr/bin/env bash
set -euo pipefail

# Husky runs this before every commit and push (.husky/pre-commit and .husky/pre-push).
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR/.."

# Format everything. If that changed any file, stop, so the changes can be reviewed and
# committed first; otherwise they'd be left out of this commit or push.
before=$(git diff)
pnpm run format
if [ "$(git diff)" != "$before" ]; then
    echo "pnpm run format changed files. Review them with git diff, commit them, and try again." >&2
    exit 1
fi

pnpm run lint
pnpm run dbt:check
pnpm run docs:generate
