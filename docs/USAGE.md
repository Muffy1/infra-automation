# Usage guide

## Bring a brand new repo up to spec

```bash
# 1. Auth gh (one time)
gh auth login

# 2. Run the provisioner
gh repo clone Muffy1/infra-automation
bash infra-automation/scripts/provision-new-repo.sh Muffy1/my-new-repo --stack node
```

That command will:
- Create the repo (if it doesn't exist) with description + README + MIT license
- Drop in `.github/` (workflows + templates + dependabot + CODEOWNERS)
- Add `SECURITY.md`
- Enable vulnerability alerts + automated security fixes
- Set branch protection on the default branch
- Apply the standard label set
- Wire CI through the reusable workflows in this repo

## Adopt an existing repo

```bash
# 1. Clone
gh repo clone Muffy1/some-existing-repo /tmp/some-existing-repo
cd /tmp/some-existing-repo

# 2. Run provisioner (it detects existing repos and updates them)
bash /path/to/infra-automation/scripts/provision-new-repo.sh Muffy1/some-existing-repo

# 3. (Optional) Audit
gh repo view Muffy1/some-existing-repo
```

## Re-apply protection after manual fiddling

```bash
bash scripts/protect-main.sh Muffy1/repo
```

## Sync topics to a batch of repos

```bash
cat repos.txt
# Muffy1/foo
# Muffy1/bar
# Muffy1/baz

bash scripts/sync-topics.sh --from-file repos.txt
```

## Audit an open queue

```bash
bash scripts/audit-issues.sh Muffy1/repo --days 30
```

## Call the reusable Android workflow

```yaml
jobs:
  android:
    uses: Muffy1/infra-automation/.github/workflows/android-build.yml@main
    with:
      java-version: "17"
      gradle-args: "assembleDebug"
      # validate-wrapper: true  # default
      # aab-path: "app/build/outputs/bundle/**/*.aab"
    secrets:
      SIGNING_KEYSTORE_B64: ${{ secrets.SIGNING_KEYSTORE_B64 }}
      SIGNING_KEYSTORE_PASSWORD: ${{ secrets.SIGNING_KEYSTORE_PASSWORD }}
      SIGNING_KEY_ALIAS: ${{ secrets.SIGNING_KEY_ALIAS }}
      SIGNING_KEY_PASSWORD: ${{ secrets.SIGNING_KEY_PASSWORD }}
```

Signing secrets are optional. When `SIGNING_KEYSTORE_B64` is non-empty, the workflow decodes it to `${{ runner.temp }}/release.keystore` and exports `SIGNING_KEYSTORE_FILE` (absolute path) via `GITHUB_ENV`. Prefer `SIGNING_KEYSTORE_FILE` in Gradle when present; the Build step still injects B64/password/alias/key password env vars. Do not commit keystores.

`validate-wrapper` (default `true`) runs `gradle/actions/wrapper-validation` after checkout. Set `false` to skip.

| Secret | Purpose |
| ------ | ------- |
| `SIGNING_KEYSTORE_B64` | Base64 of the `.jks` keystore (encode on the caller) |
| `SIGNING_KEYSTORE_PASSWORD` | Keystore password |
| `SIGNING_KEY_ALIAS` | Key alias |
| `SIGNING_KEY_PASSWORD` | Key password |

Use `apk-path`, `aab-path`, and `mapping-path` to override artifact globs (relative to `working-directory`). Uploads include APK, AAB, and mapping paths when `upload-artifacts` is true (`if-no-files-found: warn`). Set `upload-artifacts: false` for test-only runs that should not upload artifacts.

## When the reusable workflow changes

Just push to `main` in this repo. Every consumer that uses `@main` picks
it up immediately. To pin, change `@main` → `@v1.0.0` in consumer repos.
