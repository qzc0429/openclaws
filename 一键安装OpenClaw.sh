#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/install-openclaw.sh"
EXIT_CODE=$?

echo
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "OpenClaw installation finished."
else
  echo "OpenClaw installation failed. Exit code: ${EXIT_CODE}"
fi

if [[ -t 0 ]]; then
  read -r -p "Press Enter to continue..." _
fi

exit "$EXIT_CODE"
