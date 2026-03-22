#!/bin/bash
# sync-briefing-to-s3.sh
#
# PostToolUse hook: After a briefing markdown is written, upload it to S3
# with YAML frontmatter prepended to match daily.cantoramann.com format.
#
# Expects JSON on stdin with tool_input.file_path from the Write tool.
# Requires: AWS CLI configured (or AWS_ACCESS_KEY_ID/SECRET in env)

set -euo pipefail

# Ensure standard tools are on PATH
export PATH="/usr/bin:/usr/local/bin:/bin:$HOME/.local/bin:$PATH"

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only process briefing markdown files
# Patterns: briefing-YYYY-MM-DD.md (English) or briefing-YYYY-MM-DD-tr.md (Turkish)
if [[ ! "$FILE_PATH" =~ briefings/briefing-[0-9]{4}-[0-9]{2}-[0-9]{2}(-tr)?\.md$ ]]; then
  exit 0
fi

# Detect language and extract date from filename
BASENAME=$(basename "$FILE_PATH")
if [[ "$BASENAME" =~ -tr\.md$ ]]; then
  LANG="tr"
  DATE=$(echo "$BASENAME" | sed 's/briefing-\(.*\)-tr\.md/\1/')
else
  LANG="en"
  DATE=$(echo "$BASENAME" | sed 's/briefing-\(.*\)\.md/\1/')
fi

# Validate file exists
if [[ ! -f "$FILE_PATH" ]]; then
  echo "File not found: $FILE_PATH" >&2
  exit 0
fi

# Load env from repo root .env (one level above plugin dir)
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

# Detect if file already has YAML frontmatter (starts with ---)
FIRST_LINE=$(head -1 "$FILE_PATH")

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

if [[ "$FIRST_LINE" == "---" ]]; then
  # File has existing frontmatter — extract title from it, then pass through as-is
  TITLE=$(awk '/^---$/{n++; next} n==1 && /^title:/{gsub(/^title: *"?|"? *$/,"",$0); print; exit}' "$FILE_PATH")

  if [[ -z "$TITLE" ]]; then
    # Frontmatter exists but no title field — find the first H1 after frontmatter
    TITLE=$(awk '/^---$/{n++; next} n>=2 && /^# /{sub(/^# /,""); print; exit}' "$FILE_PATH")
  fi

  # Rewrite frontmatter with canonical fields, preserve body
  BODY_START=$(awk '/^---$/{n++} n==2{print NR; exit}' "$FILE_PATH")
  BODY_START=$((BODY_START + 1))

  cat > "$TEMP_FILE" << FRONTMATTER
---
title: "$TITLE"
date: $DATE
language: $LANG
author: "Can's Daily Briefing"
---
FRONTMATTER

  tail -n +"$BODY_START" "$FILE_PATH" >> "$TEMP_FILE"
else
  # No frontmatter — extract title from first H1 heading
  TITLE=$(echo "$FIRST_LINE" | sed 's/^# //')

  cat > "$TEMP_FILE" << FRONTMATTER
---
title: "$TITLE"
date: $DATE
language: $LANG
author: "Can's Daily Briefing"
---

FRONTMATTER

  # Skip the first heading line since title is now in frontmatter
  tail -n +2 "$FILE_PATH" >> "$TEMP_FILE"
fi

# Upload to S3 matching the site's content structure: content/{lang}/YYYY-MM-DD.md
S3_KEY="content/${LANG}/${DATE}.md"

aws s3 cp "$TEMP_FILE" "s3://${S3_BUCKET}/${S3_KEY}" \
  --region "${AWS_REGION:-us-west-2}" \
  --content-type "text/markdown; charset=utf-8" \
  --cache-control "public, max-age=3600" \
  2>&1

if [[ $? -eq 0 ]]; then
  echo "Briefing uploaded to s3://${S3_BUCKET}/${S3_KEY}"
else
  echo "S3 upload failed" >&2
fi

exit 0
