# Contributing

This repo holds reusable workflows and provisioning scripts for `Muffy1/*`.
Agents and people follow the same rules. See [AGENTS.md](AGENTS.md).

## Changes

- Open a pull request into `main`. `main` is protected.
- Use a conventional commit title (`feat:`, `fix:`, `docs:`, `chore:`).
- Keep the change focused. A workflow edit and an unrelated script do not
  belong in the same PR.
- Scripts are bash with `set -euo pipefail`, idempotent, and safe to re-run.
  Document `--revert` when a script installs something.
- Secrets stay in GitHub Actions secrets or the environment. Never commit a
  token, key, or `.env`.

## CLI coding agents

`scripts/install-cli-coding-agents.sh` only installs a tool when all of these
are true:

- It appears in [awesome-cli-coding-agents](https://github.com/bradAGI/awesome-cli-coding-agents) as a terminal agent or a piece of agent infrastructure.
- The package or release binary is published by that project (npm scope, PyPI
  project, or GitHub release), not by an unrelated name.
- It installs on Linux without a prompt and without removing safety checks.
- The command it provides does not overwrite a system binary.

Add the package to the `NPM_TOOLS` or `PY_TOOLS` array (or a binary installer
function), link the primary command, and update
[docs/cli-coding-agents/README.md](docs/cli-coding-agents/README.md) and
[docs/cli-coding-agents/COMMUNITY.md](docs/cli-coding-agents/COMMUNITY.md).

Run `shellcheck scripts/install-cli-coding-agents.sh` and
`./scripts/install-cli-coding-agents.sh --check` before opening the PR.

New catalog entries for the upstream directory go to that repository, not here.
The acceptance rules are summarized in the community doc.

## Checks

Workflows in `.github/workflows/` are the CI for this repo. Match their style:
small files, pinned third-party actions, no paid services required.
