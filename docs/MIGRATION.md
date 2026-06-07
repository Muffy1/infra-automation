# Migration — adopt this infra on an existing repo

## One-time per repo

```bash
# 1. Ensure gh is authenticated
gh auth status

# 2. Run the provisioner (works on existing repos too)
bash scripts/provision-new-repo.sh muffy86/existing-repo --stack python

# 3. Review the diff
gh pr diff muffy86/existing-repo  # if you PR'd it, otherwise just review
```

The provisioner will:
- Add `.github/` with workflows (no destructive change to existing workflows)
- Add `SECURITY.md`, `CODEOWNERS`, `dependabot.yml` if missing
- Add issue + PR templates if missing
- Enable vulnerability alerts + automated security fixes
- Set branch protection on the default branch
- Apply the standard label set (only adds missing labels)

It will NOT:
- Delete anything
- Rewrite history
- Change the default branch (see below for that)
- Touch non-`.github/` files

## Renaming `master` → `main`

```bash
gh api -X POST repos/muffy86/REPO/refs/heads \
  -f ref=refs/heads/main -f sha="$(gh api repos/muffy86/REPO/git/refs/heads/master -q .object.id)"
gh api -X PATCH repos/muffy86/REPO -f default_branch=main
gh api -X DELETE repos/muffy86/REPO/git/refs/heads/master
```

Then update any local clones: `git branch -m master main`.

## Removing a workflow that's already in the consumer repo

If a repo already has a `.github/workflows/ci.yml` and you want to
delegate to the reusable one:

```bash
# In the consumer repo
gh workflow disable .github/workflows/ci.yml
# (or delete the file and commit)
git rm .github/workflows/ci.yml
git commit -m "ci: delegate to infra-automation"
git push
```
