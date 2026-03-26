#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_SYSTEM="unknown"

case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
  linux*) CURRENT_SYSTEM="linux" ;;
  darwin*) CURRENT_SYSTEM="macos" ;;
esac

normalize_choice() {
  local raw="${1:-}"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$raw" in
    1|auto) echo "auto" ;;
    2|windows|win) echo "windows" ;;
    3|mac|macos|darwin) echo "macos" ;;
    4|linux) echo "linux" ;;
    5|exit|quit) echo "exit" ;;
    *) return 1 ;;
  esac
}

choice_raw="${OPENCLAW_SELECTOR_CHOICE:-auto}"

if ! target="$(normalize_choice "$choice_raw")"; then
  echo "Unsupported choice: $choice_raw"
  exit 1
fi

if [[ "$target" == "exit" ]]; then
  echo "Exited."
  exit 0
fi

if [[ "$target" == "auto" ]]; then
  if [[ "$CURRENT_SYSTEM" == "unknown" ]]; then
    echo "Cannot auto-detect current system."
    exit 1
  fi
  target="$CURRENT_SYSTEM"
fi

echo "Detected system: ${CURRENT_SYSTEM}"
echo "Selected target: ${target}"

if [[ "$target" != "$CURRENT_SYSTEM" ]]; then
  case "$target" in
    windows)
      echo "Target OS differs from current OS. Cannot run Windows installer here."
      echo "Run these on Windows:"
      echo "  powershell -NoProfile -ExecutionPolicy Bypass -File .\\install-openclaw.ps1"
      ;;
    macos)
      echo "Target OS differs from current OS. Cannot run macOS installer here."
      echo "Run these on macOS:"
      echo "  chmod +x ./install-openclaw.sh"
      echo "  ./install-openclaw.sh"
      ;;
    linux)
      echo "Target OS differs from current OS. Cannot run Linux installer here."
      echo "Run these on Linux:"
      echo "  chmod +x ./install-openclaw.sh"
      echo "  ./install-openclaw.sh"
      ;;
  esac
  exit 0
fi

installer="$SCRIPT_DIR/install-openclaw.sh"
if [[ ! -f "$installer" ]]; then
  echo "Missing installer script: install-openclaw.sh"
  exit 1
fi

echo "Running installer: install-openclaw.sh"
bash "$installer"
