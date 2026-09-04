# infra-automation

**Central reusable GitHub Actions workflows and provisioning scripts for `Muffy1/*`.**

This repo is the automation backbone. Every other repo can call into it
with one line:

```yaml
# In a consumer repo's .github/workflows/ci.yml
on: [push, pull_request]
jobs:
  ci:
    uses: Muffy1/infra-automation/.github/workflows/ci-node.yml@main
    with:
      node-version: "20"
      package-manager: pnpm
```

Android (Gradle APK/AAB):

```yaml
jobs:
  android:
    uses: Muffy1/infra-automation/.github/workflows/android-build.yml@main
    with:
      java-version: "17"
      gradle-args: "assembleDebug"
      # validate-wrapper: true   # default; Gradle wrapper checksum validation
      # aab-path: "app/build/outputs/bundle/**/*.aab"
    secrets:
      SIGNING_KEYSTORE_B64: ${{ secrets.SIGNING_KEYSTORE_B64 }}
      SIGNING_KEYSTORE_PASSWORD: ${{ secrets.SIGNING_KEYSTORE_PASSWORD }}
      SIGNING_KEY_ALIAS: ${{ secrets.SIGNING_KEY_ALIAS }}
      SIGNING_KEY_PASSWORD: ${{ secrets.SIGNING_KEY_PASSWORD }}
```

Signing secrets are optional — `assembleDebug` works without them. When `SIGNING_KEYSTORE_B64` is set, the workflow decodes it to a temp file and exports `SIGNING_KEYSTORE_FILE` (prefer that path in Gradle). Wrapper validation runs by default after checkout. See [docs/USAGE.md](docs/USAGE.md).

## Layout

```
infra-automation/
├── .github/workflows/         # the reusable workflows themselves
│   ├── ci-node.yml
│   ├── ci-rust.yml
│   ├── ci-python.yml
│   ├── android-build.yml
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
| Android  | `android-build.yml`     | Gradle APK/AAB builds             |
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
