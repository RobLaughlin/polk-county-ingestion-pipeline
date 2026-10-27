#!/usr/bin/env bash
set -euo pipefail

# Formats and lints the project. Husky runs this before every commit (.husky/pre-commit), and
# as the first step of `pnpm run check:all` before every push (.husky/pre-push).
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
