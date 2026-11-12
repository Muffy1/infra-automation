# Security

## Reporting

Report a vulnerability in this repository through a private
[GitHub security advisory](https://github.com/Muffy1/infra-automation/security/advisories/new).
Include the workflow or script, the version or commit, and a way to reproduce
the issue. Please avoid opening a public issue for an unfixed vulnerability.

## What lives here

These workflows and scripts provision repositories and, optionally, terminal
coding agents. They are not a place to store credentials.

- Tokens and API keys belong in GitHub Actions secrets or in the environment
  of the machine running a script.
- `scripts/install-cli-coding-agents.sh` downloads official release artifacts
  and package-registry builds. It does not embed keys, and `--check` prints
  only whether a variable is set.
- A provisioning script must be safe to re-run and must not weaken branch
  protection or disable secret scanning.

## Supported scope

The default branch and the tagged workflows under `.github/workflows/` are in
scope, as are the scripts under `scripts/`. Vulnerabilities in third-party
agents installed by the provisioner should be reported to that agent project.
Links are in [docs/cli-coding-agents/COMMUNITY.md](docs/cli-coding-agents/COMMUNITY.md).
