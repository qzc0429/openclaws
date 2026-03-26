#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set +e
bash "${SCRIPT_DIR}/openclaw-installer-selector.sh"
EXIT_CODE=$?
set -e

if [[ -t 0 && "${OPENCLAW_NONINTERACTIVE:-0}" != "1" && "${OPENCLAW_TEST_MODE:-0}" != "1" ]]; then
  read -r -p "Press Enter to continue..." _
fi

exit "$EXIT_CODE"
