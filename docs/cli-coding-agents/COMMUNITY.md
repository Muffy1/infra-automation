# Community resources

Notes from reading
[bradAGI/awesome-cli-coding-agents](https://github.com/bradAGI/awesome-cli-coding-agents)
on 2026-11-12, plus the community files for this infrastructure repo.

The upstream project is a curated directory of terminal coding agents and the
harnesses that run them. Its tree is `README.md`, `banner.png`,
`scripts/update-stars.py`, and `.github/workflows/update-stars.yml`. There is
no docs site in that repo. The README's own "last updated" line was 2026-11-09.
The repository has no license, so this file links to it and does not copy the
list.

## What the directory covers

A CLI coding agent, in that list's terms, is a terminal program that can read
and edit a repo and run commands, then iterate on the result. The README groups
the field like this:

1. **Terminal-native agents, open source.** Forkable tools, sorted by GitHub
   stars. The head of the list is Hermes Agent, OpenCode, Claw Code, Codex CLI,
   Pi, Gemini CLI, OpenHands, Cline, Goose, and Aider, followed by a long tail
   of smaller harnesses (Crush, Qwen Code, Kilo, SWE-agent, Plandex, Mistral
   Vibe, gptme, and many single-binary Rust and Go agents).
2. **OpenClaw ecosystem.** Assistants and runtimes built around OpenClaw:
   OpenClaw itself, nanobot, ZeroClaw, NanoClaw, PicoClaw, IronClaw, and
   smaller forks.
3. **Closed source.** Usable, not forkable. Claude Code, Warp, GitHub Copilot
   in the CLI, Cursor CLI, Amp, Factory Droid, JetBrains Junie, Snowflake
   Cortex Code, Devin, and other vendor CLIs.
4. **Session managers and parallel runners.** Tools that keep several of the
   agents above running side by side, usually with git worktrees and tmux or a
   desktop shell. Large names in that section include Orca, Multica, herdr,
   AionUi, and cmux.
5. **Orchestrators and autonomous loops.** Multi-agent loops that plan, spawn
   a coding CLI, and stop when a check passes. DeerFlow, claude-flow, OpenAI
   Symphony, and a large set of Ralph-style loops live here.
6. **Agent infrastructure.** Sandboxes, context compressors, memory, routers,
   and browser tools that sit beside an agent. Headroom, Beads, agent-browser,
   and OpenViking are the largest entries.

Star counts in the upstream README are refreshed by a scheduled workflow.
Treat them as a sort key, not a promise.

## How upstream accepts entries

PRs are open on that repository. An entry needs a terminal interface, the
ability to read or write code or run commands on its own, and a link that
still resolves to a live project. IDE-only tools are out. The README asks for
the name, a link, the star count, and one or two lines on who it is for, placed
in star order inside the matching section.

File those changes on
[bradAGI/awesome-cli-coding-agents](https://github.com/bradAGI/awesome-cli-coding-agents/pulls).
Changes to *this* provisioner (the installer and these docs) follow
[CONTRIBUTING.md](../../CONTRIBUTING.md).

## Official project homes

These are the projects the installer actually provisions. Issue trackers are
the support channel unless the project publishes a forum of its own.

| Project | Home |
| --- | --- |
| Claude Code | https://github.com/anthropics/claude-code |
| Codex CLI | https://github.com/openai/codex |
| Gemini CLI | https://github.com/google-gemini/gemini-cli |
| OpenCode | https://github.com/anomalyco/opencode |
| Pi | https://github.com/earendil-works/pi |
| Aider | https://github.com/Aider-AI/aider |
| Goose | https://github.com/aaif-goose/goose |
| OpenHands | https://github.com/OpenHands/OpenHands |
| Cline | https://github.com/cline/cline |
| Continue | https://github.com/continuedev/continue |
| Crush | https://github.com/charmbracelet/crush |
| Qwen Code | https://github.com/QwenLM/qwen-code |
| Kilo Code | https://github.com/Kilo-Org/kilocode |
| Hermes Agent | https://github.com/NousResearch/hermes-agent |
| Mistral Vibe | https://github.com/mistralai/mistral-vibe |
| gptme | https://github.com/gptme/gptme |
| Open Interpreter | https://github.com/openinterpreter/open-interpreter |
| Beads | https://github.com/gastownhall/beads |
| Amp | https://ampcode.com/docs |
| Cursor Agent | https://cursor.com/docs/cli/overview |
| Copilot CLI | https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli |
| Deep Agents Code | https://www.langchain.com/dcode |
| Tau | https://github.com/huggingface/tau |

Install, auth, and command names:
[README.md](README.md).

## Left manual on purpose

The directory lists several hundred projects. Installing every one is not a
working environment: many are desktop apps, many wrap the CLIs above, and a
few are the wrong package under a familiar name. This provisioner keeps the
following out.

**Official agent, no Linux package verified in this pass.** Factory Droid,
Devin, Junie, Snowflake Cortex Code, Tabnine CLI, Poolside `pool`, Augment
Auggie, Amazon Q Developer CLI, and Warp. Install those from the vendor when
you have an account. OpenClaw and the rest of that ecosystem are separate
products with their own onboarding; they are not pulled in as dependencies of
the coding CLIs.

**Harnesses that drive the CLIs above.** Session managers, Ralph loops, and
sandboxes expect `claude`, `codex`, `opencode`, or `goose` to exist first.
This provisioner adds two of them, and leaves the rest for a manual install
from the upstream section that matches the way you want to run it.

- Parallel runner: [Herdr](https://github.com/herdrdev/herdr), command `herdr`.
  One Rust binary. It owns the terminals the agents already use.
- Autonomous loop: [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator),
  command `ralph`. It keeps an installed backend (`claude`, `codex`, `gemini`,
  `opencode`, `pi`, and others) in a loop until the task is done.
- Harness already present: Beads (`bd`) for a local issue graph.

DeerFlow, claude-flow, Symphony, Orca, Multica, AionUi, cmux, Headroom, and
OpenViking stay out of the installer. Desktop shells in those sections do not
fit a Linux host that already has the CLIs.

**Packages whose names collide with the real tools.**

- npm `hermes-agent` is an unofficial bridge. The Nous Research package is on
  PyPI as `hermes-agent`.
- npm `grok` is an unrelated toy package, not xAI Grok Build.
- npm `droid-cli` is an Android helper, not Factory's Droid.
- PyPI `goose-ai` is not Block/AAIF Goose. Goose comes from the aaif-goose
  release installer.
- PyPI `sweagent` 0.0.1 publishes no console script. SWE-agent's own docs are
  at https://swe-agent.com and https://github.com/SWE-agent/SWE-agent.

**Safety.** Free Code is a fork described as having guardrails removed. Claw
Code and Claurst are rewrites built from a leaked Claude Code tree. This
provisioner installs Anthropic's published `@anthropic-ai/claude-code` package
for that workflow.

## This repo's community profile

| File | Role |
| --- | --- |
| [LICENSE](../../LICENSE) | MIT |
| [CONTRIBUTING.md](../../CONTRIBUTING.md) | How to change scripts and workflows |
| [CODE_OF_CONDUCT.md](../../CODE_OF_CONDUCT.md) | Expected behavior |
| [SECURITY.md](../../SECURITY.md) | How to report a vulnerability |
| [.github/ISSUE_TEMPLATE/](../../.github/ISSUE_TEMPLATE/) | Bug and triage issues |
| [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md) | PR checklist |
| [AGENTS.md](../../AGENTS.md) | Rules for agents committing here |
