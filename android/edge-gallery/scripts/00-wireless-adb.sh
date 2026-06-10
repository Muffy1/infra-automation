#!/usr/bin/env bash
# Pair and connect to an Android device over Wi-Fi (Android 11+ wireless debugging).
# Usage: ./00-wireless-adb.sh [<ip>:<connect-port>]
set -euo pipefail

command -v adb >/dev/null || { echo "ERROR: adb not found. Install platform-tools: https://developer.android.com/tools/releases/platform-tools" >&2; exit 1; }

if adb get-state >/dev/null 2>&1; then
  echo "Already connected: $(adb devices -l | sed -n 2p)"
  exit 0
fi

cat <<'EOF'
On the phone: Settings → Developer options → Wireless debugging → ON
Then tap "Pair device with pairing code". You'll see:
  - a 6-digit pairing code
  - an IP:PORT for PAIRING (changes every time)
The main Wireless debugging screen shows a DIFFERENT IP:PORT for CONNECTING.
EOF

read -rp "Pairing IP:PORT (from the pairing dialog): " PAIR_ADDR
read -rp "6-digit pairing code: " PAIR_CODE
adb pair "$PAIR_ADDR" "$PAIR_CODE"

CONNECT_ADDR="${1:-}"
[ -z "$CONNECT_ADDR" ] && read -rp "Connect IP:PORT (from the main Wireless debugging screen): " CONNECT_ADDR
adb connect "$CONNECT_ADDR"

adb wait-for-device
echo "Connected. Device: $(adb shell getprop ro.product.model) (Android $(adb shell getprop ro.build.version.release))"
