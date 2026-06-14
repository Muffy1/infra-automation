#!/usr/bin/env bash
# Setup script for OpenTerminal (https://openterminal.sh)
# Installs and starts an OpenTerminal instance for AI agent use.
#
# Usage:
#   OPEN_TERMINAL_API_KEY=mysecret bash scripts/setup-open-terminal.sh docker
#   OPEN_TERMINAL_API_KEY=mysecret bash scripts/setup-open-terminal.sh pip

set -euo pipefail

INSTALL_MODE="${1:-docker}"
PORT="${OPEN_TERMINAL_PORT:-8000}"
API_KEY="${OPEN_TERMINAL_API_KEY:-}"

if [[ -z "$API_KEY" ]]; then
  if command -v openssl > /dev/null 2>&1; then
    API_KEY=$(openssl rand -hex 32)
  elif command -v python3 > /dev/null 2>&1; then
    API_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
  else
    API_KEY=$(tr -dc 'a-f0-9' < /dev/urandom | head -c 64)
  fi
  echo "  Generated API key: $API_KEY"
  echo "  Add to .env: OPEN_TERMINAL_API_KEY=$API_KEY"
fi

wait_for_health() {
  local url="$1"
  local tries=0
  echo "  Waiting for OpenTerminal to be ready..."
  while [[ $tries -lt 20 ]]; do
    if curl -sf "${url}/health" > /dev/null 2>&1; then
      echo "  Ready."
      return 0
    fi
    sleep 2
    tries=$(( tries + 1 ))
  done
  echo "  Timed out waiting for ${url}/health" >&2
  return 1
}

if [[ "$INSTALL_MODE" == "docker" ]]; then
  echo "[open-terminal] Starting via Docker on port $PORT..."
  docker rm -f open-terminal > /dev/null 2>&1 || true
  docker run -d \
    --name open-terminal \
    --restart unless-stopped \
    -p "${PORT}:8000" \
    -e "API_KEY=${API_KEY}" \
    -v open_terminal_workspace:/workspace \
    ghcr.io/open-webui/open-terminal:latest

  wait_for_health "http://localhost:${PORT}"
  echo "[open-terminal] Running at http://localhost:${PORT}"
  echo ""
  echo "Test:"
  printf '  curl -X POST http://localhost:%s/execute \\\n' "${PORT}"
  printf '    -H "Authorization: Bearer %s" \\\n' "${API_KEY}"
  printf '    -H "Content-Type: application/json" \\\n'
  printf "    -d '{\"command\":\"echo hello from OpenTerminal\"}'\n"

elif [[ "$INSTALL_MODE" == "pip" ]]; then
  echo "[open-terminal] Installing via pip in a virtual environment..."
  python3 -m venv .venv
  .venv/bin/pip install --quiet open-terminal

  echo "[open-terminal] Starting on port ${PORT}..."
  nohup .venv/bin/open-terminal run \
    --host 0.0.0.0 \
    --port "${PORT}" \
    --api-key "${API_KEY}" \
    > /tmp/open-terminal.log 2>&1 &
  PID=$!
  echo "[open-terminal] PID ${PID} | Logs: /tmp/open-terminal.log"

  wait_for_health "http://localhost:${PORT}"
  echo "[open-terminal] Running at http://localhost:${PORT}"

else
  echo "Usage: $0 [docker|pip]"
  exit 1
fi
