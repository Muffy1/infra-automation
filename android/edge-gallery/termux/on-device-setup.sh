#!/usr/bin/env bash
# Run the entire Edge Gallery setup FROM THE PHONE ITSELF — no PC needed.
# Works on Android 11+ via wireless-debugging loopback (the phone adb's into itself).
#
# 1. Install Termux from F-Droid: https://f-droid.org/packages/com.termux/
# 2. Settings → Developer options → Wireless debugging → ON
# 3. Split-screen Termux + Settings (so you can read the pairing code), then run this.
set -euo pipefail

echo "==> Installing tools in Termux"
pkg update -y >/dev/null
pkg install -y android-tools curl git >/dev/null

if ! adb get-state >/dev/null 2>&1; then
  cat <<'EOF'

In the Settings half of the screen:
  Developer options → Wireless debugging → "Pair device with pairing code"
The pairing dialog shows a 6-digit code and an IP:PORT (use the PORT only —
the IP is this phone, so we pair against 127.0.0.1).
EOF
  read -rp "Pairing PORT: " PAIR_PORT
  read -rp "6-digit code: " PAIR_CODE
  adb pair "127.0.0.1:$PAIR_PORT" "$PAIR_CODE"

  echo "Now go BACK to the main Wireless debugging screen — it shows a different IP:PORT."
  read -rp "Connect PORT: " CONN_PORT
  adb connect "127.0.0.1:$CONN_PORT"
  adb wait-for-device
fi
echo "Connected to self: $(adb shell getprop ro.product.model)"

echo "==> Fetching the toolkit"
REPO_DIR="$HOME/infra-automation"
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  git clone --depth 1 https://github.com/muffy86/infra-automation "$REPO_DIR"
fi

cd "$REPO_DIR/android/edge-gallery"
chmod +x setup.sh scripts/*.sh
./setup.sh
