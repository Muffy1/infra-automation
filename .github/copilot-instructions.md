# GitHub Copilot instructions — Muffy1/infra-automation

## Project context
Personal AI infrastructure for a hybrid Android ⇄ local workstation ⇄ cloud
stack. Agent automation, MCP servers, Z Fold edge tooling, and GitHub Actions.

## Language & style
- Bash: `set -euo pipefail`, shellcheck-clean, idempotent.
- Python: type hints, docstrings, argparse CLI with `if __name__ == "__main__"`.
- Prefer small, focused, testable steps over large monolithic scripts.

## Security
- Never suggest committing secrets, API keys, or tokens inline.
- Use `${{ secrets.* }}` for Actions and environment variables for local runs.
- Prefer least privilege; flag anything destructive or irreversible.

## Conventions
- Conventional commit titles (feat:, fix:, chore:, ci:, docs:).
- Squash merges only; linear history on `main`.
- Reversible operations preferred (settings-level changes, `--revert` flags).

## Common tasks in this repo
- Add/extend GitHub Actions workflows under `.github/workflows/`.
- Add setup scripts under `scripts/` and on-device tooling under `android/`.
- Wire MCP servers via `.mcp.json` and `AGENTS.md`.
