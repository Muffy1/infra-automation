# CLI coding agents

Terminal-native coding agents installed by
[`scripts/install-cli-coding-agents.sh`](../../scripts/install-cli-coding-agents.sh).

The catalog this set is drawn from is
[bradAGI/awesome-cli-coding-agents](https://github.com/bradAGI/awesome-cli-coding-agents)
(README dated 2026-11-09; read here on 2026-11-12). That repository is a
directory: one README, a star-count updater, and a banner. It has no license
and no install script. This provisioner installs the Linux tools that publish
an official package or release binary, and links each primary command into
`/usr/local/bin`.

Community map, upstream contribution rules, and the tools left manual:
[COMMUNITY.md](COMMUNITY.md).

## Requirements

- Linux x86_64 or arm64
- Node.js 22+ (`npm` on `PATH`)
- Python 3.11+
- `curl`, `tar`, and `sudo` when `/usr/local/bin` is not writable

The script installs `uv` for the Python tools. It does not edit shell rc files.

## Install

```bash
./scripts/install-cli-coding-agents.sh
./scripts/install-cli-coding-agents.sh --check
./scripts/install-cli-coding-agents.sh --upgrade
./scripts/install-cli-coding-agents.sh --only aider,goose
./scripts/install-cli-coding-agents.sh --list
./scripts/install-cli-coding-agents.sh --revert
```

`--check` prints one version line per command and whether a related API key
is set. It never prints key values.

`--revert` uninstalls the packages and removes the `/usr/local/bin` symlinks
recorded in `~/.local/share/cli-coding-agents/manifest.tsv`. Logins and project
config (`~/.claude`, `~/.codex`, `~/.config/goose`, and the rest) stay on disk.

Re-running the installer skips anything whose command is already on `PATH`.

## Commands

| Command | Project | Package or installer | Typical auth |
| --- | --- | --- | --- |
| `claude` | Claude Code | npm `@anthropic-ai/claude-code` | `claude` login, or `ANTHROPIC_API_KEY` |
| `codex` | Codex CLI | npm `@openai/codex` | ChatGPT login, or `OPENAI_API_KEY` |
| `gemini` | Gemini CLI | npm `@google/gemini-cli` | Google login, or `GEMINI_API_KEY` |
| `copilot` | GitHub Copilot CLI | npm `@github/copilot` | `gh auth login` and a Copilot seat |
| `pi` | Pi | npm `@earendil-works/pi-coding-agent` | Provider key in Pi config |
| `qwen` | Qwen Code | npm `@qwen-code/qwen-code` | `DASHSCOPE_API_KEY` |
| `cn` | Continue CLI | npm `@continuedev/cli` | Continue config |
| `clite` | Cline CLI | npm `@cline/cli` | Provider key (experimental CLI) |
| `kilo` | Kilo Code CLI | npm `@kilocode/cli` | `kilo` login or a provider key |
| `bd` | Beads | npm `@beads/bd` | Local issue graph, no model key |
| `amp` | Amp | npm `@ampcode/cli` | Amp account |
| `hermes` | Hermes Agent | PyPI `hermes-agent` (Nous Research) | Provider key via `hermes` setup |
| `aider` | Aider | PyPI `aider-chat` | `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` |
| `interpreter` | Open Interpreter | PyPI `open-interpreter` (with `setuptools<81`, which still provides `pkg_resources`) | `OPENAI_API_KEY` |
| `openhands` | OpenHands CLI | PyPI `openhands` | `openhands` model setup |
| `vibe` | Mistral Vibe | PyPI `mistral-vibe` | `MISTRAL_API_KEY` |
| `dcode` | Deep Agents Code | PyPI `deepagents-code` (newest release this Python can run; 0.2.x needs Python 3.14) | Any tool-calling model key |
| `tau` | Tau | PyPI `tau-ai` | Provider key |
| `gptme` | gptme | PyPI `gptme` | `OPENAI_API_KEY` or another provider |
| `opencode` | OpenCode | `https://opencode.ai/install` | Provider key inside OpenCode |
| `goose` | Goose | aaif-goose stable CLI installer | `goose configure` (skipped here) |
| `agent`, `cursor-agent` | Cursor Agent | `https://cursor.com/install` | `agent login` or `CURSOR_API_KEY` |
| `crush` | Crush | charmbracelet/crush release tarball | Provider key in Crush config |

`kilocode` is the same binary as `kilo`. `deepagents-code` is the same binary
as `dcode`. `hermes-agent` is an extra entry point from the Hermes package.

Python tools live in a uv tool environment. Only the commands in the table are
linked into `/usr/local/bin`. Extra entry points stay under `~/.local/bin`,
which is not added to `PATH`.

## Use a tool

Install does not call a model. Confirm the binary, then authenticate once:

```bash
claude --version
codex --version
gemini --version
aider --version
goose --version
opencode --version
pi --version
```

Put keys in the environment for the shell that launches the agent. Do not
commit them and do not write them into this repo:

```bash
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
export GEMINI_API_KEY="..."
export MISTRAL_API_KEY="..."
export DASHSCOPE_API_KEY="..."
```

Subscription CLIs (`claude`, `codex`, `gemini`, `copilot`, `agent`, `amp`)
can use their own login flow instead of an API key. Goose's installer is run
with `CONFIGURE=false`, so the first real session is `goose configure`.

## Docs

- Claude Code: https://code.claude.com/docs
- Codex CLI: https://developers.openai.com/codex
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- OpenCode: https://opencode.ai/docs
- Aider: https://aider.chat/docs/
- Goose: https://goose-docs.ai/
- Pi: https://github.com/earendil-works/pi
- OpenHands: https://docs.openhands.dev/
- Continue: https://docs.continue.dev/
- Crush: https://github.com/charmbracelet/crush
- Qwen Code: https://github.com/QwenLM/qwen-code
- Kilo Code: https://github.com/Kilo-Org/kilocode
- Cline: https://docs.cline.bot/
- Copilot CLI: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli
- Cursor CLI: https://cursor.com/docs/cli/overview
- Amp: https://ampcode.com/docs
- Mistral Vibe: https://github.com/mistralai/mistral-vibe
- Hermes: https://hermes-agent.nousresearch.com
- Deep Agents Code: https://www.langchain.com/dcode
- Beads: https://github.com/gastownhall/beads
- Tau: https://github.com/huggingface/tau
- gptme: https://github.com/gptme/gptme
- Open Interpreter: https://github.com/openinterpreter/open-interpreter
