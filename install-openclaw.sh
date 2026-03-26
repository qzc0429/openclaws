#!/usr/bin/env bash
set -euo pipefail

is_truthy() {
  local value="${1:-}"
  value="$(echo "$value" | tr '[:upper:]' '[:lower:]')"
  [[ "$value" == "1" || "$value" == "true" || "$value" == "yes" || "$value" == "on" ]]
}

TEST_MODE="${OPENCLAW_TEST_MODE:-0}"
NON_INTERACTIVE="${OPENCLAW_NONINTERACTIVE:-0}"
SKIP_NODE_INSTALL="${OPENCLAW_SKIP_NODE_INSTALL:-0}"
INSTALL_URL="${OPENCLAW_INSTALL_URL:-https://openclaw.ai/install.sh}"

if is_truthy "$TEST_MODE"; then
  NON_INTERACTIVE=1
  SKIP_NODE_INSTALL=1
fi

confirm_yes() {
  local prompt="$1"

  if is_truthy "$NON_INTERACTIVE"; then
    echo "$prompt (auto-approved: non-interactive mode)"
    return
  fi

  echo "$prompt"
  read -r -p "Type YES to continue: " answer
  if [[ "$answer" != "YES" ]]; then
    echo "Cancelled by user."
    exit 1
  fi
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

get_node_major_version() {
  if ! has_command node; then
    echo 0
    return
  fi

  local version
  version="$(node --version 2>/dev/null || true)"
  if [[ -z "$version" ]]; then
    echo 0
    return
  fi

  version="${version#v}"
  echo "${version%%.*}"
}

install_node_if_needed() {
  if is_truthy "$SKIP_NODE_INSTALL"; then
    echo "Skipping Node.js installation (test/skip mode enabled)."
    return
  fi

  local major
  major="$(get_node_major_version)"

  if [[ "$major" -ge 22 ]]; then
    echo "Node.js v${major} detected."
    return
  fi

  echo "Node.js v22+ is required. Attempting automatic installation..."

  if has_command brew; then
    confirm_yes "About to install Node.js using Homebrew."
    brew install node@22 || brew install node
  elif has_command apt-get; then
    confirm_yes "About to install Node.js using apt."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  elif has_command dnf; then
    confirm_yes "About to install Node.js using dnf."
    curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
    sudo dnf install -y nodejs
  elif has_command yum; then
    confirm_yes "About to install Node.js using yum."
    curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
    sudo yum install -y nodejs
  elif has_command pacman; then
    confirm_yes "About to install Node.js using pacman."
    sudo pacman -Sy --noconfirm nodejs npm
  elif has_command zypper; then
    confirm_yes "About to install Node.js using zypper."
    sudo zypper --non-interactive install nodejs22 || sudo zypper --non-interactive install nodejs
  else
    echo "No supported package manager found."
    echo "Please install Node.js 22+ manually: https://nodejs.org/"
    exit 1
  fi

  major="$(get_node_major_version)"
  if [[ "$major" -lt 22 ]]; then
    echo "Node.js installation completed, but Node 22+ is still unavailable in PATH."
    exit 1
  fi

  echo "Node.js v${major} installed successfully."
}

main() {
  echo "OpenClaw installer will start now..."
  echo "Source: ${INSTALL_URL}"

  install_node_if_needed

  local temp_installer
  temp_installer="$(mktemp "${TMPDIR:-/tmp}/openclaw-install.XXXXXX.sh")"
  trap 'rm -f "$temp_installer"' EXIT

  if is_truthy "$TEST_MODE"; then
    cat >"$temp_installer" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "OpenClaw test installer executed."
EOF
    chmod +x "$temp_installer"
  else
    if ! has_command curl && ! has_command wget; then
      echo "curl or wget is required."
      exit 1
    fi

    if has_command curl; then
      curl -fsSL "$INSTALL_URL" -o "$temp_installer"
    else
      wget -qO "$temp_installer" "$INSTALL_URL"
    fi
  fi

  if [[ ! -s "$temp_installer" ]]; then
    echo "Failed to prepare the OpenClaw installer script."
    exit 1
  fi

  confirm_yes "About to execute the downloaded OpenClaw installer script."

  bash "$temp_installer"

  echo
  echo "OpenClaw installation completed."
  echo "If the 'openclaw' command is not available immediately, open a new terminal and try again."
}

main "$@"
