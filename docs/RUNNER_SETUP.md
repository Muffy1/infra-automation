# Self-Hosted Runner Setup (RTX 4080 Super Desktop)

This doc covers wiring the desktop rig as the first self-hosted GitHub Actions runner.

## Quick start (two paths)

### Path A — Run install.sh directly on the machine (fastest)

```bash
# On the desktop box (WSL2 or native Linux)
curl -fsSL https://raw.githubusercontent.com/muffy86/infra-automation/main/hardware-bridge/install.sh \
  | bash -s -- \
    --repo muffy86/infra-automation \
    --token <REGISTRATION_TOKEN> \
    --name  rtx-4080-super \
    --labels gpu,cuda,rtx-4080-super,self-hosted
```

Get a registration token from:
`https://github.com/muffy86/infra-automation/settings/actions/runners/new`

### Path B — Trigger the GitHub Actions workflow (remote provisioning)

1. Add four secrets to the repo (`Settings → Secrets → Actions`):

   | Secret | Value |
   |---|---|
   | `RUNNER_SSH_KEY` | Contents of `~/.ssh/id_ed25519` (private key) |
   | `RUNNER_SSH_HOST` | Desktop LAN IP or hostname |
   | `RUNNER_SSH_USER` | Your Linux username on the desktop |
   | `RUNNER_REG_TOKEN` | Token from GitHub runner registration page |

2. Go to **Actions → Wire Desktop Runner → Run workflow**

The workflow will SSH into the desktop, run `install.sh`, verify the runner appeared online, and open a tracking issue.

## What install.sh does

1. Verifies `nvidia-smi` + `gh` CLI are present
2. Downloads GitHub Actions runner v2.319.1
3. Registers the runner (`config.sh --unattended`)
4. Installs a `systemd` service so the runner starts on boot
5. Installs a thermal watcher: polls GPU temp every 30s, takes the runner offline at 85°C

## Using the runner in a workflow

```yaml
jobs:
  build-gpu:
    runs-on: [self-hosted, gpu, rtx-4080-super]
    steps:
      - uses: actions/checkout@v4
      - name: GPU smoke test
        run: nvidia-smi
```

## Thermal watcher

Installed at `~/.config/hardware-bridge/thermal-watch.sh`, added to crontab with `@reboot`.

To monitor:
```bash
tail -f ~/.config/hardware-bridge/thermal.log
```

To adjust the ceiling (default 85°C):
```bash
sed -i 's/LIMIT_C=85/LIMIT_C=80/' ~/.config/hardware-bridge/thermal-watch.sh
```

## Renewing the registration token

Runner registration tokens expire after 1 hour. The runner stays registered indefinitely once configured — you only need a new token if you're re-registering from scratch.

```bash
# Generate a fresh token via gh CLI
gh api -X POST repos/muffy86/infra-automation/actions/runners/registration-token \
  --jq '.token'
```
