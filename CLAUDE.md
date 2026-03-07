# CLAUDE.md

Repository of Claude Code plugins. Each subdirectory is a self-contained plugin with its own `.claude-plugin/`, agents, skills, commands, and hooks.

## Plugins

- **`daily-briefing/`** — Multi-agent daily briefing system. 7 agents across 3 pipeline stages produce a curated news digest combining hard news with cross-domain analysis.

## Repository Structure

```
.env                    # Shared secrets (gitignored)
.gitignore
daily-briefing/         # Daily briefing plugin
  .claude-plugin/       # Plugin manifest
  agents/               # 5 scouts + cross-pollinator + composer
  briefings/            # Generated output (briefings, tracker)
  commands/             # /briefing command
  hooks/                # PostToolUse hook for S3 sync
  skills/               # Editorial philosophy, scout strategies
  README.md             # Plugin-specific docs
```

## Git Workflow

- Commit messages: imperative mood, concise
- No force pushes to main
- **Never add Co-Authored-By, Signed-off-by, or any author/co-author trailer to commits.** All commits belong to the user. Do not attribute work to an AI agent in commit metadata.

## Environment

Shared `.env` at repo root. Individual plugins reference it via relative path traversal from their hooks. Never commit `.env`.

## Adding a New Plugin

1. Create a new directory at repo root (e.g., `my-plugin/`)
2. Add `.claude-plugin/plugin.json` inside it
3. Add agents, skills, commands, hooks as needed
4. If the plugin needs secrets, add them to the root `.env`
5. Update this file and `README.md` with the new plugin
