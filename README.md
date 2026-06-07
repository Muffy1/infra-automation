# infra-automation

**Central reusable GitHub Actions workflows and provisioning scripts for `muffy86/*`.**

This repo is the automation backbone. Every other repo can call into it
with one line:

```yaml
# In a consumer repo's .github/workflows/ci.yml
on: [push, pull_request]
jobs:
  ci:
    uses: muffy86/infra-automation/.github/workflows/ci-node.yml@main
    with:
      node-version: "20"
      package-manager: pnpm
```

## Layout

```
infra-automation/
├── .github/workflows/         # the reusable workflows themselves
│   ├── ci-node.yml
│   ├── ci-rust.yml
│   ├── ci-python.yml
│   ├── security.yml
│   ├── stale.yml
│   ├── release.yml
│   └── auto-label.yml
├── scripts/                   # provisioning scripts (run from any repo)
│   ├── provision-new-repo.sh
│   ├── protect-main.sh
│   ├── sync-topics.sh
│   └── audit-issues.sh
├── docs/
│   ├── USAGE.md
│   ├── HARDWARE.md
│   └── MIGRATION.md
└── .github/ISSUE_TEMPLATE/
    ├── infra-task.md
    └── bug.md
```

## Stacks covered

| Stack    | Reusable workflow       | Use case                          |
| -------- | ----------------------- | --------------------------------- |
| Node/TS  | `ci-node.yml`           | Next.js, React, Vite, Express     |
| Rust     | `ci-rust.yml`           | Native services, CLIs, WASM       |
| Python   | `ci-python.yml`         | FastAPI, ML, scripts              |
| Security | `security.yml`          | gitleaks + CodeQL                 |
| Hygiene  | `stale.yml`             | Stale issue/PR close              |
| Release  | `release.yml`           | Tag → build → GitHub Release      |
| Triage   | `auto-label.yml`        | Path-based auto-labeling          |

## Free-friendly, no lock-in

- All runners are public `ubuntu-latest` (free for public repos).
- AI integrations are abstracted: swap providers without rewriting
  workflows. See `docs/HARDWARE.md` for the local LLM bridge.
- No paid third-party actions. Only first-party + maintained community
  actions (downloads pinned to SHA, not tag, where it matters).

## How to use

1. In any repo, copy `scripts/provision-new-repo.sh` to a fresh repo.
2. Run it; it adds `CODEOWNERS`, branch protection, the `.github/`
   folder, Dependabot, and replaces the workflows with `uses:` calls
   into this repo.
3. From then on, all CI/CD changes happen here, in one place.
