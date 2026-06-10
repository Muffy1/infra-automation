#!/usr/bin/env bash
# Z Fold performance tuning for heavy on-device LLM inference.
# All changes are settings-level and reversible: ./04-zfold-tune.sh --revert
set -euo pipefail

PKG="com.google.ai.edge.gallery"
adb get-state >/dev/null 2>&1 || { echo "ERROR: no device connected" >&2; exit 1; }

if [ "${1:-}" = "--revert" ]; then
  echo "==> Reverting tuning"
  adb shell settings put global settings_enable_monitor_phantom_procs true
  adb shell device_config set_sync_disabled_for_tests none
  adb shell device_config put activity_manager max_phantom_processes 32
  adb shell settings delete system min_refresh_rate 2>/dev/null || true
  adb shell dumpsys deviceidle whitelist "-$PKG" >/dev/null
  echo "Reverted."
  exit 0
fi

echo "==> Disabling phantom process killer (Android 12+ kills heavy child procs mid-inference)"
# keep our flag from being overwritten by server-side config sync
adb shell device_config set_sync_disabled_for_tests persistent 2>/dev/null || true
adb shell device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null || true
adb shell settings put global settings_enable_monitor_phantom_procs false

echo "==> Pinning 120Hz on the main display (smoother token streaming UI)"
adb shell settings put system min_refresh_rate 120.0 2>/dev/null || echo "    (not supported on this firmware — skipping)"

echo "==> Verifying"
echo "    phantom monitor: $(adb shell settings get global settings_enable_monitor_phantom_procs | tr -d '\r') (want: false)"
echo "    max phantom procs: $(adb shell device_config get activity_manager max_phantom_processes | tr -d '\r')"
echo "    thermal status: $(adb shell dumpsys thermalservice 2>/dev/null | grep -m1 'Thermal Status' | tr -d '\r' || echo n/a)"

cat <<'EOF'

Manual Z Fold settings worth flipping once (no ADB knob exists):
  - Settings → Battery → Background usage limits → Never sleeping apps → add AI Edge Gallery
  - Settings → Display → Full screen apps → enable for AI Edge Gallery (cover display)
  - Settings → Advanced features → Labs → "Multi window for all apps" (run the
    Gallery split-screen next to Termux/notes while it generates)
  - Game Booster: if it grabbed the app, remove it (Game Booster throttles non-games)
EOF
