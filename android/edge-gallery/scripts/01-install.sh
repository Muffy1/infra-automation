#!/usr/bin/env bash
# Install (or update) Google AI Edge Gallery from the latest GitHub release APK.
# Usage: ./01-install.sh
set -euo pipefail

PKG="com.google.ai.edge.gallery"
REPO="google-ai-edge/gallery"

command -v adb >/dev/null || { echo "ERROR: adb not found" >&2; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "ERROR: no device connected — run 00-wireless-adb.sh first" >&2; exit 1; }

if adb shell pm list packages | grep -q "^package:$PKG$"; then
  INSTALLED_VER=$(adb shell dumpsys package "$PKG" | grep -m1 versionName | cut -d= -f2 | tr -d '\r')
  echo "Already installed: $PKG $INSTALLED_VER (will sideload latest release on top)"
fi

echo "Fetching latest release APK from github.com/$REPO ..."
APK_URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | cut -d'"' -f4)
[ -n "$APK_URL" ] || { echo "ERROR: no APK asset found in latest release" >&2; exit 1; }

# mktemp -d is portable (BSD/macOS lacks GNU's --suffix)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
TMP_APK="$TMP_DIR/gallery.apk"
curl -fL -o "$TMP_APK" "$APK_URL"

# -r reinstall keeping data, -d allow same/older version, -g grant runtime perms
adb install -r -d -g "$TMP_APK"
echo "Installed: $(adb shell dumpsys package "$PKG" | grep -m1 versionName | tr -d '\r')"
