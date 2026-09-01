#!/usr/bin/env bash
# Download LiteRT models from Hugging Face and push them to the phone for import.
# Usage:  [HF_TOKEN=hf_xxx] ./03-models.sh <model> [<model> ...]
#         ./03-models.sh --list
#         ./03-models.sh --file /path/to/local/model.litertlm
#
# Gemma models are license-gated: accept the license at huggingface.co once,
# then create a read token (hf.co/settings/tokens) and pass it via HF_TOKEN.
set -euo pipefail

DEVICE_DIR="/sdcard/Download"   # the Gallery's "+" file picker defaults here
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/edge-gallery-models"

# name|huggingface-repo|filename
CATALOG=$(cat <<'EOF'
gemma3-1b|litert-community/Gemma3-1B-IT|Gemma3-1B-IT_multi-prefill-seq_q8_ekv2048.task
gemma3n-e2b|google/gemma-3n-E2B-it-litert-lm|gemma-3n-E2B-it-int4.litertlm
gemma3n-e4b|google/gemma-3n-E4B-it-litert-lm|gemma-3n-E4B-it-int4.litertlm
qwen2.5-1.5b|litert-community/Qwen2.5-1.5B-Instruct|Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task
phi4-mini|litert-community/Phi-4-mini-instruct|Phi-4-mini-instruct_multi-prefill-seq_q8_ekv1280.task
deepseek-r1-1.5b|litert-community/DeepSeek-R1-Distill-Qwen-1.5B|DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv1280.task
EOF
)

if [ "${1:-}" = "--list" ] || [ $# -eq 0 ]; then
  echo "Available models (browse more at https://huggingface.co/litert-community):"
  echo "$CATALOG" | awk -F'|' '{printf "  %-16s %s\n", $1, $2}'
  echo
  echo "Usage: [HF_TOKEN=hf_xxx] $0 <name> [...]  |  $0 --file <local-model>"
  exit 0
fi

adb get-state >/dev/null 2>&1 || { echo "ERROR: no device connected" >&2; exit 1; }
mkdir -p "$CACHE_DIR"

push() {
  local f="$1"
  echo "==> Pushing $(basename "$f") ($(du -h "$f" | cut -f1)) to $DEVICE_DIR"
  adb push "$f" "$DEVICE_DIR/"
  # make it visible to the file picker immediately
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
    -d "file://$DEVICE_DIR/$(basename "$f")" >/dev/null 2>&1 || true
}

if [ "$1" = "--file" ]; then
  [ -f "${2:-}" ] || { echo "ERROR: file not found: ${2:-}" >&2; exit 1; }
  push "$2"
else
  for NAME in "$@"; do
    LINE=$(echo "$CATALOG" | grep "^$NAME|" || true)
    [ -n "$LINE" ] || { echo "ERROR: unknown model '$NAME' — see --list" >&2; exit 1; }
    REPO=$(echo "$LINE" | cut -d'|' -f2)
    FILE=$(echo "$LINE" | cut -d'|' -f3)
    DEST="$CACHE_DIR/$FILE"
    if [ ! -f "$DEST" ]; then
      echo "==> Downloading $REPO/$FILE"
      AUTH=()
      [ -n "${HF_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $HF_TOKEN")
      curl -fL "${AUTH[@]}" -o "$DEST.part" \
        "https://huggingface.co/$REPO/resolve/main/$FILE" \
        || { rm -f "$DEST.part"; echo "ERROR: download failed (gated model? set HF_TOKEN after accepting the license)" >&2; exit 1; }
      mv "$DEST.part" "$DEST"
    else
      echo "==> Using cached $FILE"
    fi
    push "$DEST"
  done
fi

cat <<EOF

Pushed. In the app: tap "+" (bottom-right) → pick the file from Download →
set GPU backend in the import dialog → Import.
EOF
