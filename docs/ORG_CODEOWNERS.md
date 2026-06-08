# Org-level CODEOWNERS — for `muffy86-projects`

Once the user creates the `muffy86-projects` organization, drop this
file at `.github/CODEOWNERS` in each new org repo:

```
# Default: Muffy approves everything
*       @muffy86

# Sensitive surfaces
/.env*                  @muffy86
**/secrets*             @muffy86
**/*.key                @muffy86
/kortix.toml            @muffy86

# CI / infra
/.github/workflows/     @muffy86
/scripts/               @muffy86
/docs/infra-automation/ @muffy86
```

The user can also create a `CODEOWNERS` team in the org and replace
`@muffy86` with `@muffy86-projects/CODEOWNERS` for shared ownership.

## What I will do when the org exists

- Watch for `muffy86-projects/*` repos to appear
- Apply this CODEOWNERS to each
- Apply branch protection (same defaults as personal account)
- Wire CI to delegate to `muffy86/infra-automation/.github/workflows/*@main`
- Mirror the label set

The `repo-provisioner` skill does this already; only the org-name
parameter changes.
