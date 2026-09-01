# AGENTS.md — Operating rules for AI agents in this repo

This repository is the operational home for Muffy1's personal AI infrastructure
(agent automation, MCP servers, Android/Z Fold edge tooling, GitHub Actions).
Both human contributors and autonomous agents commit here. Follow these rules.

## Principles
- **Local-first, private, self-hosted.** Prefer components that run on our own
  hardware (Android Termux, local workstation, homelab) over SaaS lock-in.
- **Least privilege.** Use scoped tokens; never commit secrets, tokens, or keys.
  Secrets live in GitHub Actions secrets or a password manager, referenced as
  `${{ secrets.NAME }}` or env vars — never inline.
- **Reproducible.** Scripts must be idempotent and safe to re-run. Document
  usage and reversibility (e.g. `--revert`).
- **Verify, don't assume.** After making changes, confirm they actually work
  (run the script, check CI) before reporting success.

## Workflow
- Work in a branch (or open a PR). `main` is protected: PRs are required,
  force-push and deletions are disabled.
- Keep PRs focused and squashed. Use conventional commit titles.
- If a task is long or multi-step, update progress in the issue/PR instead of
  going silent.

## Conventions
- Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, shellcheck-clean.
- Python: type hints, docstrings, argparse CLIs, `if __name__ == "__main__"`.
- Config/CI lives under `.github/`. Keep workflows small and readable.

## Capability map
- `scripts/` — reusable setup/automation scripts (OpenTerminal, Notte, ADB,
  Z Fold Edge Gallery).
- `android/` — on-device tooling (Termux, wireless ADB, model sideloading).
- `.github/workflows/` — CI and scheduled automation.
- `AGENTS.md` — this file; `.github/copilot-instructions.md` — Copilot context.

## When in doubt
Ask before doing anything destructive, credential-related, or irreversible
(delete, force-push, visibility change, secret access). Prefer the least
autonomy needed for safe completion.
