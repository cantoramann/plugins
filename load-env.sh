#!/bin/bash
# load-env.sh
#
# SessionStart hook: loads .env from repo root into the Claude Code session
# via CLAUDE_ENV_FILE so all subsequent hooks inherit the credentials.
#
# This avoids committing secrets to git while ensuring PostToolUse hooks
# (like S3 sync) have access to AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.

set -euo pipefail

# Resolve repo root (this script lives at repo root)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  # No .env file — nothing to inject, exit silently
  exit 0
fi

if [[ -z "${CLAUDE_ENV_FILE:-}" ]]; then
  # CLAUDE_ENV_FILE not set — older Claude Code version or non-session context
  exit 0
fi

# Write each non-comment, non-empty line as an export into the session env file
grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | while IFS= read -r line; do
  echo "export $line"
done >> "$CLAUDE_ENV_FILE"
