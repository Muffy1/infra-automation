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
  API_KEY=$(openssl rand -hex 32)
  echo "  Generated API key: $API_KEY"
  echo "  Add to .env: OPEN_TERMINAL_API_KEY=$API_KEY"
fi

wait_for_health() {
  local url="$1"
  echo "  Waiting for OpenTerminal to be ready..."
  for i in {1..20}; do
    if curl -sf "$url/health" > /dev/null 2>&1; then
      echo "  Ready."
      return 0
    fi
    sleep 2
  done
  echo "  Timed out waiting for $url/health" >&2
  return 1
}

if [[ "$INSTALL_MODE" == "docker" ]]; then
  echo "[open-terminal] Starting via Docker on port $PORT..."
  docker run -d \
    --name open-terminal \
    --restart unless-stopped \
    -p "${PORT}:8000" \
    -e "API_KEY=$API_KEY" \
    -v open_terminal_workspace:/workspace \
    ghcr.io/open-webui/open-terminal:latest

  wait_for_health "http://localhost:$PORT"
  echo "[open-terminal] Running at http://localhost:$PORT"
  echo ""
  echo "Test:"
  echo "  curl -X POST http://localhost:$PORT/execute \\"
  echo "    -H 'Authorization: Bearer $API_KEY' \\"
  echo "    -H 'Content-Type: application/json' \\"
  echo "    -d '{\"command\":\"echo hello from OpenTerminal\"}'"

elif [[ "$INSTALL_MODE" == "pip" ]]; then
  echo "[open-terminal] Installing via pip..."
  pip install --quiet open-terminal

  echo "[open-terminal] Starting on port $PORT..."
  nohup open-terminal run \
    --host 0.0.0.0 \
    --port "$PORT" \
    --api-key "$API_KEY" \
    > /tmp/open-terminal.log 2>&1 &
  PID=$!
  echo "[open-terminal] PID $PID | Logs: /tmp/open-terminal.log"

  wait_for_health "http://localhost:$PORT"
  echo "[open-terminal] Running at http://localhost:$PORT"

else
  echo "Usage: $0 [docker|pip]"
  exit 1
fi
