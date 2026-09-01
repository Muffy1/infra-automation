#!/usr/bin/env bash
# Configure Google AI Edge Gallery for reliable long-running on-device inference:
# grant permissions, exempt from battery/background kill, AOT-compile.
# Usage: ./02-configure.sh
set -euo pipefail

PKG="com.google.ai.edge.gallery"

adb get-state >/dev/null 2>&1 || { echo "ERROR: no device connected" >&2; exit 1; }
adb shell pm list packages | grep -q "^package:$PKG$" || { echo "ERROR: $PKG not installed — run 01-install.sh" >&2; exit 1; }

echo "==> Granting runtime permissions (camera/mic for multimodal, notifications)"
for PERM in android.permission.CAMERA android.permission.RECORD_AUDIO android.permission.POST_NOTIFICATIONS; do
  adb shell pm grant "$PKG" "$PERM" 2>/dev/null || echo "    (skip $PERM — not requested by this app version)"
done

echo "==> Exempting from Doze / battery optimization"
adb shell dumpsys deviceidle whitelist "+$PKG" >/dev/null

echo "==> Allowing unrestricted background execution (survives Samsung app sleep)"
adb shell cmd appops set "$PKG" RUN_IN_BACKGROUND allow
adb shell cmd appops set "$PKG" RUN_ANY_IN_BACKGROUND allow 2>/dev/null || true
adb shell am set-standby-bucket "$PKG" active

echo "==> AOT-compiling for fastest startup (takes ~30s)"
adb shell cmd package compile -m speed -f "$PKG" || true

echo "==> Verifying"
adb shell dumpsys deviceidle whitelist | grep -q "$PKG" && echo "    battery whitelist: OK"
echo "    standby bucket: $(adb shell am get-standby-bucket "$PKG" | tr -d '\r')"

cat <<EOF

Done. One manual step ADB can't reach on Samsung:
  Settings → Battery → Background usage limits → "Never sleeping apps" → add AI Edge Gallery
EOF
