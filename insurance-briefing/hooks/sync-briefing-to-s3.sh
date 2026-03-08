#!/bin/bash
# sync-briefing-to-s3.sh
set -euo pipefail
export PATH="/usr/bin:/usr/local/bin:/bin:$HOME/.local/bin:$PATH"

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Check if file matches briefing pattern (briefing-YYYY-MM-DD.md)
if [[ "$FILE_PATH" =~ briefings/briefing-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  # Extract date from filename
  BASENAME=$(basename "$FILE_PATH")
  DATE=$(echo "$BASENAME" | sed 's/briefing-\(.*\)\.md/\1/')

  if [[ ! -f "$FILE_PATH" ]]; then
    echo "File not found: $FILE_PATH" >&2
    exit 0
  fi

  # Load env from repo root .env
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
  REPO_ROOT="$(dirname "$PLUGIN_DIR")"
  ENV_FILE="$REPO_ROOT/.env"

  if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
  fi

  # Check required env vars
  if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" || -z "${S3_BUCKET:-}" ]]; then
    echo "Missing AWS credentials or S3_BUCKET. Skipping S3 upload." >&2
    exit 0
  fi

  # Extract title, create frontmatter, upload
  FIRST_LINE=$(head -1 "$FILE_PATH")
  TITLE=$(echo "$FIRST_LINE" | sed 's/^# //')

  TEMP_FILE=$(mktemp)
  trap 'rm -f "$TEMP_FILE"' EXIT

  cat > "$TEMP_FILE" << FRONTMATTER
---
title: "$TITLE"
date: $DATE
language: tr
author: "Sigorta Brifing"
---

FRONTMATTER

  tail -n +2 "$FILE_PATH" >> "$TEMP_FILE"

  S3_KEY="content/insurance/tr/${DATE}.md"

  aws s3 cp "$TEMP_FILE" "s3://${S3_BUCKET}/${S3_KEY}" \
    --region "${AWS_REGION:-us-west-2}" \
    --content-type "text/markdown; charset=utf-8" \
    --cache-control "public, max-age=3600" \
    2>&1

  exit 0
fi

# Check if file matches personalization pattern (personalization-YYYY-MM-DD.json)
if [[ "$FILE_PATH" =~ briefings/personalization-[0-9]{4}-[0-9]{2}-[0-9]{2}\.json$ ]]; then
  # Extract date from filename
  BASENAME=$(basename "$FILE_PATH")
  DATE=$(echo "$BASENAME" | sed 's/personalization-\(.*\)\.json/\1/')

  if [[ ! -f "$FILE_PATH" ]]; then
    echo "File not found: $FILE_PATH" >&2
    exit 0
  fi

  # Load env from repo root .env
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
  REPO_ROOT="$(dirname "$PLUGIN_DIR")"
  ENV_FILE="$REPO_ROOT/.env"

  if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
  fi

  # Check required env vars
  if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" || -z "${S3_BUCKET:-}" ]]; then
    echo "Missing AWS credentials or S3_BUCKET. Skipping S3 upload." >&2
    exit 0
  fi

  S3_KEY="personalization/insurance/${DATE}.json"

  aws s3 cp "$FILE_PATH" "s3://${S3_BUCKET}/${S3_KEY}" \
    --region "${AWS_REGION:-us-west-2}" \
    --content-type "application/json" \
    --cache-control "public, max-age=3600" \
    2>&1

  exit 0
fi

# File doesn't match any pattern, exit silently
exit 0
