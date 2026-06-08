# hardware-bridge — self-hosted GitHub Actions runner

This is a one-shot setup script that registers the user's desktop rig
(RTX 4080 Super, i9, 4 TB SSD, liquid cooled) as a self-hosted GitHub
Actions runner, then exposes a small set of CI jobs that route
GPU-heavy work to it.

## Quick start (run on the desktop, not the sandbox)

```bash
# 1. Clone infra-automation
gh repo clone muffy86/infra-automation ~/infra-automation

# 2. Run the install
bash ~/infra-automation/hardware-bridge/install.sh

# 3. Register the runner with your account
# (the script will prompt for a token from
#  https://github.com/settings/actions/runners/new)
```

## What the install does

1. Detects NVIDIA driver + CUDA via `nvidia-smi`
2. Downloads the `actions/runner` release
3. Configures it as a self-hosted runner labeled
   `self-hosted,linux,x64,gpu,cuda,rtx-4080-super`
4. Installs the runner as a systemd service (`gh-runner.service`)
5. Sets the runner to "online" and ready
6. Prints a smoke-test workflow snippet to drop into a repo

## What it can run

| Job                    | GPU? | Time on 4080S |
| ---------------------- | ---- | ------------- |
| `cargo test`           | no   | 2-5× faster than free runner |
| `uv run pytest`        | no   | 2-3× faster |
| `ollama run qwen2.5:32b` | yes | 20 tok/s, 20 GB VRAM |
| `pytorch training`     | yes  | 4-8× faster than CPU |
| `transformers inference` | yes | 10-50× faster than CPU |

## Thermal policy

`install.sh` installs a small watcher that polls
`nvidia-smi --query-gpu=temperature.gpu` every 30s. If the GPU exceeds
85°C, it:
1. Marks the runner as "offline" so GitHub doesn't dispatch new jobs
2. Logs the event to `/var/log/gh-runner-thermal.log`
3. Sends a notification to your Telegram (if TELEGRAM_BOT_TOKEN is set)

## Calling the runner from a workflow

```yaml
jobs:
  gpu-job:
    runs-on: [self-hosted, gpu, cuda, rtx-4080-super]
    steps:
      - uses: actions/checkout@v4
      - name: Verify GPU
        run: nvidia-smi
      - name: Train
        run: python train.py --epochs 10
```

## Security notes

- The runner has access to your GitHub PAT, your local files, and any
  secrets in repo/org settings
- Don't run untrusted PRs against the self-hosted runner — use
  `pull_request_target` carefully and sandbox where possible
- The systemd service runs as the user who installed it; use a
  dedicated `gh-runner` user for additional isolation

## What this is NOT

- Not a cloud GPU. The runner is just your desktop. It must be powered
  on and online for jobs to run.
- Not free. You're paying the electricity bill.
- Not shared. Only the repos you register the runner for can use it.
