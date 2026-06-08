#!/usr/bin/env bash
# install.sh — install + register a self-hosted GitHub Actions runner
# on a Linux box with NVIDIA GPU.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/muffy86/infra-automation/main/hardware-bridge/install.sh | bash
#   bash install.sh --repo muffy86/some-repo --token <TOKEN> --labels gpu,cuda,rtx-4080-super
#
# Args:
#   --repo       owner/repo to register against (default: prompts)
#   --token      registration token from
#                https://github.com/<owner>/<repo>/settings/actions/runners/new
#                (or https://github.com/organizations/<org>/settings/actions/runners/new)
#   --name       runner name (default: hostname)
#   --labels     comma-separated extra labels (default: gpu,cuda,rtx-4080-super)
#   --user       system user to run the service as (default: current)
#   --no-service don't install systemd service
set -euo pipefail

REPO=""
TOKEN=""
NAME="$(hostname)"
LABELS="gpu,cuda,rtx-4080-super"
USER="$(whoami)"
NO_SERVICE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --labels) LABELS="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --no-service) NO_SERVICE=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# 1. Verify prerequisites
echo "=== hardware-bridge install ==="
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi not found. Install NVIDIA driver + CUDA first." >&2
  echo "  Ubuntu: sudo apt install nvidia-driver-550" >&2
  exit 1
fi

GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
VRAM_MIB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
echo "GPU:    $GPU_NAME"
echo "VRAM:   ${VRAM_MIB} MiB"
echo "Driver: $DRIVER"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI required. Install: https://cli.github.com" >&2
  exit 1
fi

# 2. Determine target
if [[ -z "$REPO" ]]; then
  read -rp "Target repo (owner/repo): " REPO
fi
if [[ -z "$TOKEN" ]]; then
  echo "Get a registration token from:"
  if [[ "$REPO" == */* ]]; then
    if gh api "orgs/${REPO%%/*}" >/dev/null 2>&1; then
      echo "  https://github.com/organizations/${REPO%%/*}/settings/actions/runners/new"
    else
      echo "  https://github.com/${REPO%%/*}/${REPO##*/}/settings/actions/runners/new"
    fi
  fi
  read -rsp "Registration token: " TOKEN
  echo
fi

# 3. Download + extract runner
RUNNER_VERSION="2.319.1"
RUNNER_DIR="$HOME/actions-runner"
if [[ ! -d "$RUNNER_DIR" ]]; then
  echo "Downloading runner $RUNNER_VERSION..."
  mkdir -p "$RUNNER_DIR"
  curl -fsSL -o /tmp/runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  tar -xzf /tmp/runner.tar.gz -C "$RUNNER_DIR"
fi

# 4. Configure
cd "$RUNNER_DIR"
./config.sh --unattended \
  --replace \
  --url "https://github.com/$REPO" \
  --token "$TOKEN" \
  --name "$NAME" \
  --labels "$LABELS" \
  --work _work

# 5. systemd service
if [[ $NO_SERVICE -eq 0 ]]; then
  echo "Installing systemd service..."
  sudo ./svc.sh install "$USER"
  sudo ./svc.sh start
  sudo systemctl status "actions.runner.${REPO//\//-}.${NAME}" --no-pager || true
fi

# 6. Thermal watcher
THERMAL_DIR="$HOME/.config/hardware-bridge"
mkdir -p "$THERMAL_DIR"
cat > "$THERMAL_DIR/thermal-watch.sh" <<'WATCH'
#!/usr/bin/env bash
# Poll GPU temp; if > 85C, mark runner offline.
LIMIT_C=85
LOG="$HOME/.config/hardware-bridge/thermal.log"
SERVICE="actions.runner.$(hostname).service"
mkdir -p "$(dirname "$LOG")"
while true; do
  TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  if [[ -n "$TEMP" ]] && (( TEMP > LIMIT_C )); then
    echo "$(date -Iseconds) HIGH ${TEMP}C - taking runner offline" >> "$LOG"
    if command -v systemctl >/dev/null && systemctl --user is-active "$SERVICE" >/dev/null 2>&1; then
      systemctl --user stop "$SERVICE"
    elif sudo -n systemctl is-active "$SERVICE" >/dev/null 2>&1; then
      sudo systemctl stop "$SERVICE"
    fi
  fi
  sleep 30
done
WATCH
chmod +x "$THERMAL_DIR/thermal-watch.sh"

# Add to crontab if not already
( crontab -l 2>/dev/null | grep -v thermal-watch.sh
  echo "@reboot $THERMAL_DIR/thermal-watch.sh >/dev/null 2>&1"
) | crontab -

echo ""
echo "=== install complete ==="
echo "  runner name: $NAME"
echo "  labels:      $LABELS"
echo "  service:     $(systemctl is-active actions.runner.* 2>/dev/null || echo 'not managed by systemd')"
echo "  thermal:     $THERMAL_DIR/thermal-watch.sh (in crontab)"
echo ""
echo "To use it from a workflow:"
echo "  runs-on: [self-hosted, $(echo $LABELS | tr ',' '\n' | head -1 | xargs)]"
