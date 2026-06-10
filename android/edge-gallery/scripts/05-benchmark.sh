#!/usr/bin/env bash
# Launch Edge Gallery and capture a performance snapshot: inference logs,
# memory, GPU frame stats, thermal state. Output goes to ./bench-<timestamp>/
# Usage: ./05-benchmark.sh [capture-seconds]   (default 60)
set -euo pipefail

PKG="com.google.ai.edge.gallery"
DURATION="${1:-60}"
OUT="bench-$(date +%Y%m%d-%H%M%S)"

adb get-state >/dev/null 2>&1 || { echo "ERROR: no device connected" >&2; exit 1; }
mkdir -p "$OUT"

echo "==> Launching $PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3

echo "==> Capturing for ${DURATION}s — interact with the app now (run a prompt!)"
adb logcat -c
adb logcat -v time > "$OUT/logcat-full.txt" &
LOGCAT_PID=$!
trap 'kill "$LOGCAT_PID" 2>/dev/null || true' EXIT
sleep "$DURATION"
kill "$LOGCAT_PID" 2>/dev/null || true
wait "$LOGCAT_PID" 2>/dev/null || true

# inference-relevant lines (MediaPipe/LiteRT/XNNPACK log tokens-per-second etc.)
grep -iE 'litert|mediapipe|llm|xnnpack|tflite|gpu delegate|tok' "$OUT/logcat-full.txt" > "$OUT/inference.txt" || true

echo "==> Collecting system snapshots"
adb shell dumpsys meminfo "$PKG"        > "$OUT/meminfo.txt"
adb shell dumpsys gfxinfo "$PKG"        > "$OUT/gfxinfo.txt"
adb shell dumpsys thermalservice        > "$OUT/thermal.txt" 2>/dev/null || true
adb shell cat /proc/meminfo             > "$OUT/system-meminfo.txt"

echo
echo "==> Summary"
echo "    App PSS: $(grep -m1 'TOTAL PSS' "$OUT/meminfo.txt" | tr -s ' ' | tr -d '\r' || echo n/a)"
echo "    Thermal: $(grep -m1 'Thermal Status' "$OUT/thermal.txt" | tr -d '\r' 2>/dev/null || echo n/a)"
echo "    Inference log lines: $(wc -l < "$OUT/inference.txt")"
echo
echo "Full capture in: $OUT/"
