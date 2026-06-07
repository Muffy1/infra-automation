# Usage guide

## Bring a brand new repo up to spec

```bash
# 1. Auth gh (one time)
gh auth login

# 2. Run the provisioner
gh repo clone muffy86/infra-automation
bash infra-automation/scripts/provision-new-repo.sh muffy86/my-new-repo --stack node
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
gh repo clone muffy86/some-existing-repo /tmp/some-existing-repo
cd /tmp/some-existing-repo

# 2. Run provisioner (it detects existing repos and updates them)
bash /path/to/infra-automation/scripts/provision-new-repo.sh muffy86/some-existing-repo

# 3. (Optional) Audit
gh repo view muffy86/some-existing-repo
```

## Re-apply protection after manual fiddling

```bash
bash scripts/protect-main.sh muffy86/repo
```

## Sync topics to a batch of repos

```bash
cat repos.txt
# muffy86/foo
# muffy86/bar
# muffy86/baz

bash scripts/sync-topics.sh --from-file repos.txt
```

## Audit an open queue

```bash
bash scripts/audit-issues.sh muffy86/repo --days 30
```

## When the reusable workflow changes

Just push to `main` in this repo. Every consumer that uses `@main` picks
it up immediately. To pin, change `@main` → `@v1.0.0` in consumer repos.
