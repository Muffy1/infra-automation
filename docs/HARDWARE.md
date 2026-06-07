# Hardware bridge — local dev ↔ GitHub

The local rig (i9 + RTX 4080 Super + 4 TB SSD + liquid cooling) is the
heavy-lift machine. The laptop (Lenovo Yoga AI 5) and the two Android
phones (Galaxy Z Fold 7, Pixel 9 Pro Fold) are the lightweight edges.

This file is the contract for moving work between them with zero
friction.

## Local AI bridge (RTX 4080 Super)

The 4080 Super has 16 GB VRAM. That fits:

| Model                     | Quant    | VRAM    | Use                          |
| ------------------------- | -------- | ------- | ---------------------------- |
| Llama 3.1 8B              | Q4_K_M   | ~5 GB   | fast general agent           |
| Qwen 2.5 14B              | Q4_K_M   | ~10 GB  | code-heavy agent             |
| DeepSeek Coder 33B        | IQ3_M    | ~12 GB  | bulk code completion         |
| nomic-embed-text          | -        | ~0.5 GB | embeddings for RAG           |

Recommended stack:
- **Ollama** for the model server (one `ollama serve` in tmux)
- **Open WebUI** for the chat UI on `localhost:8080`
- **llama.cpp** for direct embedding + scripting
- A `~/.config/kortix/hardware.json` that the agent reads to decide
  which model to call

## What the agent does automatically

The agent skill `local-dev-orchestrator` reads hardware at session
start and:

1. Detects the GPU, VRAM, and disk
2. Picks a model profile (`fast`, `balanced`, `heavy`)
3. Stands up Ollama + Open WebUI in tmux if not already running
4. Surfaces a `localhost:8080` URL the user can open
5. Configures the workspace's `kortix.toml` model defaults to point at
   the local server when available, with cloud fallback when not

## Android + laptop sync

| Device                     | Sync method                                   |
| -------------------------- | --------------------------------------------- |
| Galaxy Z Fold 7            | Termux + `gh` CLI + repo clones (read-mostly) |
| Pixel 9 Pro Fold           | Termux + `gh` CLI + repo clones (read-mostly) |
| Lenovo Yoga AI 5           | Full dev (smaller LLM profile, no GPU-bound)  |
| Desktop (this rig)         | Full dev (LLM, training, builds)              |

All three Android clients authenticate with the same `GITHUB_TOKEN`,
so PR reviews, issue triage, and "small fix" commits work from any
device.

## CI in the cloud (no local GPU)

GitHub Actions runners don't have a GPU. So:

- Heavy training jobs run on the desktop with `runs-on: self-hosted` if
  you add a self-hosted runner to a repo
- Default reusable workflows target `ubuntu-latest` (CPU, free tier)
- Code-generated and lighter models run on the cloud (Venice free tier,
  Groq, OpenRouter)
- Anything that needs the 4080 Super is dispatched to the desktop via
  a tmux + ssh bridge (see `scripts/remote-train.sh` placeholder)

## Power & thermals

Liquid cooling handles sustained 200W+ loads fine. The agent checks
`nvidia-smi --query-gpu=temperature.gpu` before dispatching a job and
aborts > 85°C.
