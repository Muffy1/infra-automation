#!/usr/bin/env bash
# install-cli-coding-agents.sh — provision terminal coding agents on Linux.
#
# Installs the agents from bradAGI/awesome-cli-coding-agents that publish an
# official package or release binary and run non-interactively on Linux.
# Primary commands are symlinked into /usr/local/bin. API keys stay in the
# environment; this script never writes credentials.
#
# Usage:
#   ./scripts/install-cli-coding-agents.sh
#   ./scripts/install-cli-coding-agents.sh --check
#   ./scripts/install-cli-coding-agents.sh --upgrade
#   ./scripts/install-cli-coding-agents.sh --only aider,goose
#   ./scripts/install-cli-coding-agents.sh --only npm
#   ./scripts/install-cli-coding-agents.sh --list
#   ./scripts/install-cli-coding-agents.sh --revert
#
# Re-running is safe. --revert removes the symlinks and the tool installs.
# Provider config directories (~/.claude, ~/.codex, ~/.config/goose, …) stay
# in place so a later install keeps existing logins.
set -euo pipefail

PREFIX="${CLI_AGENTS_PREFIX:-$HOME/.local}"
ROOT_BIN="${CLI_AGENTS_BIN:-$PREFIX/bin}"
STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cli-coding-agents"
MANIFEST="$STATE_DIR/manifest.tsv"
UPGRADE=0
DO_CHECK=0
DO_REVERT=0
ONLY=""
failures=0

# package|comma-separated commands
NPM_TOOLS=(
  "@anthropic-ai/claude-code|claude"
  "@openai/codex|codex"
  "@google/gemini-cli|gemini"
  "@github/copilot|copilot"
  "@earendil-works/pi-coding-agent|pi"
  "@qwen-code/qwen-code|qwen"
  "@continuedev/cli|cn"
  "@cline/cli|clite"
  "@kilocode/cli|kilo,kilocode"
  "@beads/bd|bd"
  "@ampcode/cli|amp"
  "@ralph-orchestrator/ralph-cli|ralph"
)

# PyPI distribution|comma-separated commands[|extra requirement]
# open-interpreter still imports pkg_resources, which left setuptools in v82.
PY_TOOLS=(
  "hermes-agent|hermes,hermes-agent"
  "aider-chat|aider"
  "open-interpreter|interpreter|setuptools<81"
  "openhands|openhands"
  "mistral-vibe|vibe"
  "deepagents-code|dcode,deepagents-code"
  "tau-ai|tau"
  "gptme|gptme"
)

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

note_fail() {
  failures=$((failures + 1))
  warn "$*"
}

# selected <group> <comma-separated-commands>
# True when --only is unset, or names this group, or names one of its commands.
selected() {
  local group="$1" bins="$2" bin
  local -a parts=()
  [[ -z "$ONLY" ]] && return 0
  [[ ",${ONLY}," == *",${group},"* ]] && return 0
  IFS=',' read -r -a parts <<<"$bins"
  for bin in "${parts[@]}"; do
    [[ ",${ONLY}," == *",${bin},"* ]] && return 0
  done
  return 1
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$cmd" >&2
    exit 1
  fi
}

record_link() {
  local name="$1" src="$2"
  mkdir -p "$STATE_DIR"
  if [[ -f "$MANIFEST" ]] && grep -qxF "${name}"$'\t'"${src}" "$MANIFEST"; then
    return 0
  fi
  printf '%s\t%s\n' "$name" "$src" >>"$MANIFEST"
}

link_bin() {
  local name="$1" src="$2" dest
  dest="/usr/local/bin/$name"
  if [[ ! -e "$src" ]]; then
    warn "missing binary for $name ($src)"
    return 1
  fi
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    warn "$dest exists and is not a symlink; left it alone"
    return 1
  fi
  if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    record_link "$name" "$src"
    return 0
  fi
  if [[ -w /usr/local/bin ]]; then
    ln -sfn "$src" "$dest"
  else
    sudo ln -sfn "$src" "$dest"
  fi
  record_link "$name" "$src"
  log "linked $dest -> $src"
}

present() {
  local cmd="$1"
  [[ -x "$ROOT_BIN/$cmd" || -x "/usr/local/bin/$cmd" ]]
}

install_uv() {
  if command -v uv >/dev/null 2>&1 && [[ "$UPGRADE" -eq 0 ]]; then
    log "uv already installed ($(uv --version 2>/dev/null | head -1))"
    return 0
  fi
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 UV_INSTALL_DIR="$ROOT_BIN" sh
  link_bin uv "$ROOT_BIN/uv" || true
  if [[ -x "$ROOT_BIN/uvx" ]]; then
    link_bin uvx "$ROOT_BIN/uvx" || true
  fi
}

link_cmds() {
  local bins="$1" bin
  local -a parts=()
  IFS=',' read -r -a parts <<<"$bins"
  for bin in "${parts[@]}"; do
    if [[ -e "$ROOT_BIN/$bin" ]]; then
      link_bin "$bin" "$ROOT_BIN/$bin" || note_fail "link $bin"
    else
      note_fail "expected $ROOT_BIN/$bin"
    fi
  done
}

install_npm_tools() {
  local entry pkg bins bin
  for entry in "${NPM_TOOLS[@]}"; do
    pkg="${entry%%|*}"
    bins="${entry#*|}"
    bin="${bins%%,*}"
    selected npm "$bins" || continue
    if [[ "$UPGRADE" -eq 0 ]] && present "$bin"; then
      log "$bin already installed"
    else
      log "npm install $pkg"
      if ! npm install -g --prefix "$PREFIX" --no-fund --no-audit "$pkg"; then
        note_fail "npm $pkg"
        continue
      fi
    fi
    link_cmds "$bins"
  done
}

install_python_tools() {
  local entry pkg rest bins extra bin
  local -a uv_args=()
  export UV_TOOL_BIN_DIR="$ROOT_BIN"
  for entry in "${PY_TOOLS[@]}"; do
    pkg="${entry%%|*}"
    rest="${entry#*|}"
    extra=""
    if [[ "$rest" == *"|"* ]]; then
      bins="${rest%%|*}"
      extra="${rest#*|}"
    else
      bins="$rest"
    fi
    bin="${bins%%,*}"
    selected python "$bins" || continue
    if [[ "$UPGRADE" -eq 0 ]] && present "$bin"; then
      log "$bin already installed"
    else
      uv_args=(tool install)
      if [[ "$UPGRADE" -eq 1 ]]; then
        uv_args+=(--upgrade)
      fi
      if [[ -n "$extra" ]]; then
        uv_args+=(--with "$extra")
      fi
      uv_args+=("$pkg")
      log "uv ${uv_args[*]}"
      uv "${uv_args[@]}" || { note_fail "uv $pkg"; continue; }
    fi
    link_cmds "$bins"
  done
}

install_opencode() {
  if [[ "$UPGRADE" -eq 0 ]] && present opencode; then
    log "opencode already installed"
    link_bin opencode "${HOME}/.opencode/bin/opencode" || link_bin opencode "$ROOT_BIN/opencode" || note_fail "link opencode"
    return 0
  fi
  log "Installing OpenCode"
  curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
  if [[ -x "${HOME}/.opencode/bin/opencode" ]]; then
    link_bin opencode "${HOME}/.opencode/bin/opencode" || note_fail "link opencode"
  else
    note_fail "opencode binary missing after installer"
  fi
}

install_goose() {
  if [[ "$UPGRADE" -eq 0 ]] && present goose; then
    log "goose already installed"
    link_bin goose "$ROOT_BIN/goose" || note_fail "link goose"
    return 0
  fi
  log "Installing Goose"
  curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
    | env CONFIGURE=false GOOSE_BIN_DIR="$ROOT_BIN" bash
  link_bin goose "$ROOT_BIN/goose" || note_fail "link goose"
}

install_herdr() {
  if [[ "$UPGRADE" -eq 0 ]] && present herdr; then
    log "herdr already installed"
    link_bin herdr "$ROOT_BIN/herdr" || note_fail "link herdr"
    return 0
  fi
  log "Installing Herdr"
  curl -fsSL https://herdr.dev/install.sh | env HERDR_INSTALL_DIR="$ROOT_BIN" sh
  link_bin herdr "$ROOT_BIN/herdr" || note_fail "link herdr"
}

install_cursor_agent() {
  if [[ "$UPGRADE" -eq 0 ]] && present cursor-agent; then
    log "cursor-agent already installed"
    link_bin cursor-agent "$ROOT_BIN/cursor-agent" || note_fail "link cursor-agent"
    link_bin agent "$ROOT_BIN/agent" || note_fail "link agent"
    return 0
  fi
  log "Installing Cursor Agent"
  # PATH includes ROOT_BIN so the installer skips its shell-rc instructions.
  PATH="$ROOT_BIN:$PATH" curl -fsSL https://cursor.com/install | bash
  link_bin cursor-agent "$ROOT_BIN/cursor-agent" || note_fail "link cursor-agent"
  link_bin agent "$ROOT_BIN/agent" || note_fail "link agent"
}

crush_url() {
  python3 - <<'PY'
import json
import platform
import urllib.request

machine = platform.machine()
suffix = {
    "x86_64": "Linux_x86_64.tar.gz",
    "aarch64": "Linux_arm64.tar.gz",
    "arm64": "Linux_arm64.tar.gz",
}.get(machine)
if suffix is None:
    raise SystemExit(f"unsupported architecture: {machine}")
req = urllib.request.Request(
    "https://api.github.com/repos/charmbracelet/crush/releases/latest",
    headers={
        "Accept": "application/vnd.github+json",
        "User-Agent": "infra-automation-cli-agents",
    },
)
with urllib.request.urlopen(req, timeout=60) as resp:
    data = json.load(resp)
for asset in data.get("assets", []):
    name = asset.get("name", "")
    if name.endswith(suffix) and "sbom" not in name:
        print(asset["browser_download_url"])
        break
else:
    raise SystemExit(f"no crush asset matching {suffix}")
PY
}

install_crush() {
  local url tmp bin
  if [[ "$UPGRADE" -eq 0 ]] && present crush; then
    log "crush already installed"
    link_bin crush "$ROOT_BIN/crush" || note_fail "link crush"
    return 0
  fi
  log "Installing Crush"
  url="$(crush_url)"
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/crush.tgz"
  tar -xzf "$tmp/crush.tgz" -C "$tmp"
  bin="$(find "$tmp" -type f -name crush | head -n 1)"
  if [[ -z "$bin" ]]; then
    rm -rf "$tmp"
    note_fail "crush archive contained no crush binary"
    return 0
  fi
  install -m 0755 "$bin" "$ROOT_BIN/crush"
  rm -rf "$tmp"
  link_bin crush "$ROOT_BIN/crush" || note_fail "link crush"
}

version_of() {
  local cmd="$1" out
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'missing'
    return 0
  fi
  # -k sends SIGKILL when a TUI ignores SIGTERM (amp --version does).
  # stdout only: several CLIs print deprecation warnings on stderr.
  out="$(timeout -k 5s 20s "$cmd" --version 2>/dev/null | head -n 1 || true)"
  if [[ -z "$out" ]]; then
    out="$(timeout -k 5s 20s "$cmd" version 2>/dev/null | head -n 1 || true)"
  fi
  if [[ -z "$out" ]]; then
    printf 'installed'
  else
    printf '%s' "$out"
  fi
}

key_state() {
  local name="$1"
  if [[ -n "${!name:-}" ]]; then
    printf 'set'
  else
    printf 'unset'
  fi
}

cmd_check() {
  local cmd="$1" key="$2" ver
  ver="$(version_of "$cmd")"
  if [[ -n "$key" ]]; then
    printf '%-16s %-8s %s\n' "$cmd" "$(key_state "$key")" "$ver"
  else
    printf '%-16s %-8s %s\n' "$cmd" "-" "$ver"
  fi
}

run_check() {
  printf '%-16s %-8s %s\n' "COMMAND" "KEY" "VERSION"
  cmd_check claude ANTHROPIC_API_KEY
  cmd_check codex OPENAI_API_KEY
  cmd_check gemini GEMINI_API_KEY
  cmd_check copilot GH_TOKEN
  cmd_check pi ""
  cmd_check qwen DASHSCOPE_API_KEY
  cmd_check cn ""
  cmd_check clite ""
  cmd_check kilo ""
  cmd_check bd ""
  cmd_check amp ""
  cmd_check hermes ""
  cmd_check aider OPENAI_API_KEY
  cmd_check interpreter OPENAI_API_KEY
  cmd_check openhands ""
  cmd_check vibe MISTRAL_API_KEY
  cmd_check dcode ""
  cmd_check tau ""
  cmd_check gptme OPENAI_API_KEY
  cmd_check opencode ""
  cmd_check goose ""
  cmd_check cursor-agent CURSOR_API_KEY
  cmd_check agent CURSOR_API_KEY
  cmd_check crush ""
  cmd_check herdr ""
  cmd_check ralph ""
  cmd_check uv ""
  printf '\nKeys show set/unset only. Values are never printed.\n'
  printf 'Login commands and docs: docs/cli-coding-agents/README.md\n'
}

revert_links() {
  local name src dest
  if [[ -f "$MANIFEST" ]]; then
    while IFS=$'\t' read -r name src; do
      [[ -z "$name" ]] && continue
      dest="/usr/local/bin/$name"
      if [[ -L "$dest" ]]; then
        if [[ -w /usr/local/bin ]]; then
          rm -f "$dest"
        else
          sudo rm -f "$dest"
        fi
        log "removed $dest"
      fi
      if [[ -n "$src" && "$src" == "$ROOT_BIN/$name" && -e "$src" ]]; then
        rm -f "$src" || true
      fi
    done <"$MANIFEST"
    rm -f "$MANIFEST"
  fi
}

revert_tools() {
  local entry pkg
  if command -v uv >/dev/null 2>&1; then
    for entry in "${PY_TOOLS[@]}"; do
      pkg="${entry%%|*}"
      uv tool uninstall "$pkg" || true
    done
  fi
  if command -v npm >/dev/null 2>&1; then
    for entry in "${NPM_TOOLS[@]}"; do
      pkg="${entry%%|*}"
      npm uninstall -g --prefix "$PREFIX" "$pkg" || true
    done
  fi
  rm -f "$ROOT_BIN/crush" "$ROOT_BIN/goose" "$ROOT_BIN/herdr" || true
  log "Provider config directories were left in place."
}

tool_bins() {
  local rest="${1#*|}"
  if [[ "$rest" == *"|"* ]]; then
    printf '%s' "${rest%%|*}"
  else
    printf '%s' "$rest"
  fi
}

list_ids() {
  local entry
  printf 'groups:\n'
  printf '  npm python opencode goose cursor crush uv\n'
  printf 'npm commands:\n'
  for entry in "${NPM_TOOLS[@]}"; do
    printf '  %s\n' "${entry#*|}"
  done
  printf 'python commands:\n'
  for entry in "${PY_TOOLS[@]}"; do
    printf '  %s\n' "$(tool_bins "$entry")"
  done
  printf 'binaries:\n'
  printf '  opencode goose cursor-agent agent crush herdr\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --check) DO_CHECK=1; shift ;;
    --upgrade) UPGRADE=1; shift ;;
    --revert) DO_REVERT=1; shift ;;
    --list) list_ids; exit 0 ;;
    --only)
      if [[ -z "${2:-}" ]]; then
        printf '--only needs a comma-separated list (see --list)\n' >&2
        exit 2
      fi
      ONLY="$2"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$DO_CHECK" -eq 1 ]]; then
  run_check
  exit 0
fi

require_cmd curl
require_cmd python3
require_cmd tar
mkdir -p "$ROOT_BIN" "$STATE_DIR"

if [[ "$DO_REVERT" -eq 1 ]]; then
  revert_tools
  revert_links
  log "Revert finished."
  exit 0
fi

require_cmd npm

export NPM_CONFIG_UPDATE_NOTIFIER=false
export PATH="$ROOT_BIN:/usr/local/bin:$PATH"

python_requested=0
if selected python ""; then
  python_requested=1
else
  entry=""
  for entry in "${PY_TOOLS[@]}"; do
    if selected python "$(tool_bins "$entry")"; then
      python_requested=1
      break
    fi
  done
fi

if [[ "$python_requested" -eq 1 || -z "$ONLY" || ",${ONLY}," == *",uv,"* ]]; then
  install_uv || note_fail "uv"
fi
if selected npm ""; then
  install_npm_tools
else
  entry=""
  for entry in "${NPM_TOOLS[@]}"; do
    if selected npm "${entry#*|}"; then
      install_npm_tools
      break
    fi
  done
fi
if [[ "$python_requested" -eq 1 ]]; then
  if ! command -v uv >/dev/null 2>&1; then
    note_fail "python tools need uv"
  else
    install_python_tools
  fi
fi
if selected opencode "opencode"; then
  install_opencode || note_fail "opencode"
fi
if selected goose "goose"; then
  install_goose || note_fail "goose"
fi
if selected cursor "cursor-agent,agent"; then
  install_cursor_agent || note_fail "cursor-agent"
fi
if selected crush "crush"; then
  install_crush || note_fail "crush"
fi
if selected herdr "herdr"; then
  install_herdr || note_fail "herdr"
fi

log "Install pass finished with ${failures} failure(s)."
run_check
if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
