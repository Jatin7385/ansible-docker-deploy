#!/usr/bin/env bash
# Installs Ansible + required collections on macOS via Homebrew.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Install it from https://brew.sh first, then re-run this script." >&2
  exit 1
fi

if ! command -v ansible &> /dev/null; then
  echo "Installing Ansible via Homebrew..."
  brew install ansible
else
  echo "Ansible already installed: $(ansible --version | head -n1)"
fi

echo "Installing required Ansible collections..."
ansible-galaxy collection install -r "$PROJECT_DIR/requirements.yml"

echo "Done. Verify with: ansible --version"
